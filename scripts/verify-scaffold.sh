#!/usr/bin/env bash
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
work="$(mktemp -d)"
server_pid=""
cleanup() {
	if [ -n "$server_pid" ]; then
		kill "$server_pid" 2>/dev/null || true
		wait "$server_pid" 2>/dev/null || true
	fi
	rm -rf "$work"
}
trap cleanup EXIT

SVELTEKIT_TEMPLATE_DIR="$repo" bash "$repo/create.sh" "$work/app"
cd "$work/app"
test -s src/lib/server/db/auth.schema.ts
# Drizzle's migration layout can vary; require an actual SQL migration.
find drizzle -name '*.sql' -type f -size +0c | grep -q .
test ! -e .github/workflows/scaffold.yml
test ! -e scripts/verify-scaffold.sh
test ! -e template
test ! -e INSTRUCTIONS.md
# Compare the installed documentation after the same formatting used by setup.
pnpm exec prettier --stdin-filepath README.md < "$repo/template/README.md" | cmp - README.md
pnpm exec prettier --stdin-filepath AGENTS.md < "$repo/template/AGENTS.md" | cmp - AGENTS.md

# Paraglide generates its runtime during the build, before type checking.
pnpm build
pnpm check
pnpm lint

HOST=127.0.0.1 PORT=4173 node --env-file=.env build >"$work/server.log" 2>&1 &
server_pid=$!
if ! node --input-type=module <<'JS'
const base = 'http://127.0.0.1:4173';
let ready = false;
for (let attempt = 0; attempt < 60; attempt++) {
  try {
    await fetch(base, { signal: AbortSignal.timeout(1000) });
    ready = true;
    break;
  } catch {
    await new Promise((resolve) => setTimeout(resolve, 500));
  }
}
if (!ready) throw new Error('Production server did not start');
for (const [path, expected] of [['/', 200], ['/__scaffold_missing_route__', 404]]) {
  const response = await fetch(base + path, { redirect: 'manual', signal: AbortSignal.timeout(5000) });
  if (response.status !== expected) {
    throw new Error(`${path}: expected ${expected}, got ${response.status}`);
  }
  console.log(`${path}: ${response.status}`);
}
JS
then
	cat "$work/server.log"
	exit 1
fi
printf 'Scaffold verification passed.\n'
