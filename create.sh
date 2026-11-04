#!/usr/bin/env bash
# Create a new SvelteKit app from kaufmann-dev/sveltekit-template.
#
#   curl -fsSL https://raw.githubusercontent.com/kaufmann-dev/sveltekit-template/main/create.sh | bash -s -- my-app
#
# Runs without prompts. Set SVELTEKIT_TEMPLATE_DIR to a local checkout to use it instead of GitHub.

set -euo pipefail

TEMPLATE_TARBALL="https://codeload.github.com/kaufmann-dev/sveltekit-template/tar.gz/main"
MIN_NODE="22.17.0"
# Pinned because new releases of these CLIs add prompts that break unattended runs.
# Bump deliberately and rerun the script to verify.
SV_VERSION="1.2.0"
SHADCN_SVELTE_VERSION="1.8.0"

log() { printf '==> %s\n' "$*"; }
die() { printf 'error: %s\n' "$*" >&2; exit 1; }

main() {
	# When piped into bash, stdin is this script: keep child processes away from it and fail
	# any interactive prompt instead of hanging.
	exec </dev/null

	[ "$#" -eq 1 ] || die "usage: create.sh <target-directory>"
	local target="$1"
	if [ -e "$target" ] && [ -n "$(ls -A "$target" 2>/dev/null)" ]; then
		die "target directory '$target' exists and is not empty"
	fi

	local tool
	for tool in node pnpm curl tar; do
		command -v "$tool" >/dev/null 2>&1 || die "'$tool' is required but not installed"
	done
	node -e '
		const [a, b] = [process.versions.node, process.argv[1]].map((v) => v.split(".").map(Number));
		const ok = a[0] - b[0] || a[1] - b[1] || a[2] - b[2];
		process.exit(ok >= 0 ? 0 : 1);
	' "$MIN_NODE" || die "Node $MIN_NODE or newer is required (found $(node --version))"

	local tmp
	tmp="$(mktemp -d)"
	# shellcheck disable=SC2064
	trap "rm -rf '$tmp'" EXIT

	if [ -n "${SVELTEKIT_TEMPLATE_DIR:-}" ]; then
		log "Copying template from $SVELTEKIT_TEMPLATE_DIR"
		tar -C "$SVELTEKIT_TEMPLATE_DIR" --exclude=.git -cf - . | tar -C "$tmp" -xf -
	else
		log "Downloading template"
		curl -fsSL "$TEMPLATE_TARBALL" | tar -xz -C "$tmp" --strip-components=1
	fi

	mkdir -p "$target"
	cp -a "$tmp/." "$target/"
	cd "$target"

	log "Creating SvelteKit app"
	pnpm dlx "sv@$SV_VERSION" create --template minimal --types ts --add tailwindcss="plugins:none" \
		drizzle="database:postgresql+client:postgres.js+docker:no" \
		better-auth="demo:none" \
		experimental="features:async,remoteFunctions" \
		eslint prettier \
		vitest="usages:unit,component" \
		paraglide="languageTags:en,de+demo:no" \
		sveltekit-adapter="adapter:node" \
		ai-tools="ide:claude-code,opencode+delivery:plugin" \
		--install pnpm . --no-dir-check
	# CLI prompts exit 0 when they read EOF, so check that each tool actually finished.
	[ -f package.json ] || die "sv create did not finish; a new sv version may ask a question that needs a flag"

	log "Restoring template README.md and AGENTS.md"
	cp -f "$tmp/INSTRUCTIONS.md" AGENTS.md
	cp -f "$tmp/README.md" README.md
	rm -f INSTRUCTIONS.md create.sh

	log "Adding packages"
	pnpm add mode-watcher @lucide/svelte zod resend better-svelte-email

	log "Initializing shadcn-svelte"
	# `--reinstall` makes init overwrite without asking. Without it, init prompts to update
	# layout.css, and with no TTY it exits 0 without installing dependencies. There are no
	# components to reinstall yet, and layout.css is replaced below.
	pnpm dlx "shadcn-svelte@$SHADCN_SVELTE_VERSION" init --reinstall \
		--preset b27GcrTs \
		--base-color neutral \
		--css src/routes/layout.css \
		--lib-alias '#lib' \
		--components-alias '#lib/components' \
		--ui-alias '#lib/components/ui' \
		--utils-alias '#lib/utils' \
		--hooks-alias '#lib/hooks'
	grep -q '"tw-animate-css"' package.json ||
		die "shadcn-svelte init did not finish; a new version may ask a question that needs a flag"
	cp -f shadcn/layout.css src/routes/layout.css

	log "Adding shadcn-svelte components"
	# `form` is left out: it depends on Superforms and formsnap. Forms use remote functions.
	pnpm dlx "shadcn-svelte@$SHADCN_SVELTE_VERSION" add --yes \
		accordion alert alert-dialog aspect-ratio attachment avatar badge breadcrumb bubble \
		button button-group calendar card carousel chart checkbox collapsible command \
		context-menu dialog drawer dropdown-menu empty field hover-card input input-group \
		input-otp item kbd label marker menubar message native-select navigation-menu \
		pagination popover progress radio-group range-calendar resizable scroll-area select \
		separator sheet sidebar skeleton slider sonner spinner switch table tabs textarea \
		toggle toggle-group tooltip
	mkdir -p src/lib/components
	cp -r shadcn/components/. src/lib/components/
	rm -rf shadcn

	log "Excluding generated shadcn-svelte components from ESLint"
	node -e '
		const fs = require("node:fs");
		const anchor = "\tincludeIgnoreFile(gitignorePath),\n";
		const src = fs.readFileSync("eslint.config.js", "utf8");
		if (!src.includes(anchor)) process.exit(1);
		const ignore = "\t// shadcn-svelte components are generated vendor code.\n\t{ ignores: [\"src/lib/components/ui/**\"] },\n";
		fs.writeFileSync("eslint.config.js", src.replace(anchor, anchor + ignore));
	' || die "could not add the shadcn-svelte ignore to eslint.config.js"

	log "Formatting"
	pnpm format

	log "Done. Next steps:"
	printf '  cd %s\n  pnpm dev\n' "$target"
	printf 'See README.md "Development Database" for a local PostgreSQL.\n'
}

main "$@"
