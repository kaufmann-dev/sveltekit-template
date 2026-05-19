# SvelteKit Agent Template
> Project-scoped agent configuration for SvelteKit projects.

## Contents
- [Create The App](#create-the-app)
- [Included](#included)
- [MCP Servers](#mcp-servers)
- [Optional Add-Ons](#optional-add-ons)

## Create The App

Start with a minimal TypeScript SvelteKit app, install with pnpm, and add only the required official `sv` add-ons:

```bash
npx sv create --template minimal --types ts --add tailwindcss drizzle better-auth sveltekit-adapter="adapter:node" --install pnpm my-app
```

Then apply this agent template inside the project:

```bash
cd my-app
npx degit kaufmann-dev/project-templates/sveltekit .
```

Add the required non-`sv` packages after creation:

```bash
pnpm add mode-watcher
pnpm add -D @iconify/tailwind4
npx shadcn-svelte@latest init
```

## Included

- `AGENTS.md` with SvelteKit, Svelte 5, shadcn-svelte, auth, database, testing, and tooling instructions.
- `.agents/skills/` and `skills-lock.json` with project-local skills.
- MCP configuration for Codex, OpenCode, Gemini CLI, and Claude Code.
- A Codex Svelte file-editor subagent.

## MCP Servers

Enabled by default:

- `svelte`
- `shadcn-svelte`

Optional MCP servers are disabled in Codex and OpenCode only:

- `playwright`
- `postgres` via `DATABASE_URL`
- `resend` via `RESEND_API_KEY`
- `glitchtip` via `GLITCHTIP_MCP_URL`

Gemini CLI and Claude Code only include the default servers because their project configs do not safely support disabled MCP entries.

## Optional Add-Ons

Only add optional technologies when the feature is actually needed.

Official `sv add` examples:

```bash
# Internationalisation
npx sv add paraglide --install pnpm

# Unit or component tests
npx sv add vitest --install pnpm

# End-to-end tests
npx sv add playwright --install pnpm
```

Other optional stack choices from `AGENTS.md`, such as Superforms, Resend, better-svelte-email, Plausible, and GlitchTip, are not listed as official `sv add` add-ons. Install and configure them only when their feature is needed.
