# SvelteKit Template

An opinionated SvelteKit starter for AI-driven development.

| Category             | Tools                                                     |
| -------------------- | --------------------------------------------------------- |
| Framework            | SvelteKit, @sveltejs/adapter-node                         |
| UI & Styling         | Tailwind CSS, shadcn-svelte, @lucide/svelte, mode-watcher |
| Data & Auth          | PostgreSQL, Drizzle ORM, Better Auth                      |
| Forms & Validation   | SvelteKit remote functions, Zod                           |
| Email                | Resend, better-svelte-email                               |
| Internationalisation | Paraglide                                                 |
| Testing & Quality    | Vitest, svelte-check, ESLint, Prettier                    |
| Local Development    | Vite, pnpm, Podman                                        |

## Get Started

Create a new app in `my-app`:

```bash
curl -fsSL https://raw.githubusercontent.com/kaufmann-dev/sveltekit-template/main/create.sh | bash -s -- my-app
```

`create.sh` downloads this template and runs `sv create` with the stack add-ons. It then installs the extra packages, initializes shadcn-svelte with the template theme and components, and puts the agent instructions in place as `AGENTS.md`. The target directory must be new or empty.

It never prompts, so an agent can run the same command without cloning this repository. It always runs the newest `sv` and `shadcn-svelte`. If a new release adds a question, the script stops with an error instead of creating a half-finished app.

Setup shows only its progress messages by default. If a command fails, it prints the failed step and captured command output, then stops. Set `VERBOSE=1` to stream command output while setup runs. When piping the installer, set it on Bash:

```bash
curl -fsSL https://raw.githubusercontent.com/kaufmann-dev/sveltekit-template/main/create.sh | VERBOSE=1 bash -s -- my-app
```

- shadcn-svelte uses the `b27GcrTs` preset: `rhea`, `neutral`, Lucide icons, Inter, a `0.45rem` radius, and the subtle menu accent. The generated stylesheet and components are kept unchanged.
- The `form` component is left out because it depends on Superforms and formsnap. Forms use remote functions with the `field` components instead.
- All listed shadcn-svelte components remain preinstalled. ESLint checks them, with narrowly scoped exceptions for the stock Button link forwarding and ChartTooltip callback parameter.

## Requirements

- Node 22.17 or newer, pnpm, curl, and tar for setup.
- Podman for the generated app's local PostgreSQL database.

## Repository Layout

- `create.sh`: non-interactive installer.
- `template/README.md`: development guide copied to the new app's `README.md`.
- `template/AGENTS.md`: app-development instructions copied to the new app's `AGENTS.md`.
- `scripts/verify-scaffold.sh`: fresh-app verification.
- `.github/workflows/scaffold.yml`: automated verification.

The installer copies the application documentation after `sv create` completes. It removes the `template/` directory, installer, and template verification files from the new app. This repository's README stays here; generated apps receive their own development guide.

To test local changes, set `SVELTEKIT_TEMPLATE_DIR` to this checkout and choose a target outside it:

```bash
SVELTEKIT_TEMPLATE_DIR="$PWD" bash create.sh ../my-app
```

For application commands, database setup, and included tooling, see [the application guide](template/README.md).

## Template Verification

GitHub Actions verifies a fresh scaffold on pushes, pull requests, daily at 06:23 UTC, and manual runs. It enables verbose setup output and uses Node 24 and the latest setup CLIs, checks that the auth schema and a SQL migration exist, runs build, type checking, and lint, then checks production HTTP responses (200 for `/`, 404 for an unknown route). It does not test database connectivity or sign-in.

From this template checkout, run the same check with `bash scripts/verify-scaffold.sh`. It creates and removes a temporary app and loads that app's `.env` for the production server. The workflow and verification script are not copied into generated applications.
