# SvelteKit Agent Template

Project-scoped agent configuration for SvelteKit projects.

## Included

- `AGENTS.md` with SvelteKit, Svelte 5, shadcn-svelte, auth, database, testing, and tooling instructions.
- `.agents/skills/` and `skills-lock.json` with project-local skills.
- MCP configuration for Codex, OpenCode, Gemini CLI, and Claude Code.
- A Codex Svelte file-editor subagent.

## MCP Servers

Enabled by default:

- `svelte`
- `shadcn-svelte`

Optional, disabled in Codex and OpenCode only:

- `playwright`
- `postgres` via `DATABASE_URL`
- `resend` via `RESEND_API_KEY`
- `glitchtip` via `GLITCHTIP_MCP_URL`

Gemini CLI and Claude Code only include the default servers because their project configs do not safely support disabled MCP entries.
