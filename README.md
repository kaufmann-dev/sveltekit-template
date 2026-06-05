# Project Templates

These are lightweight configuration templates for OpenCode and Codex. They only add AI agent settings, MCP servers, and custom skills--no framework boilerplate or project code.

To drop these settings directly into your project, just run the corresponding `degit` command.

All project templates use AGENTS.md as the default instruction file. If you are using Claude Code, rename it to CLAUDE.md, if you have not configured support for other instruction files.

## Stable

```bash
# SvelteKit
pnpm dlx degit kaufmann-dev/project-templates/sveltekit . --force --mode=tar
```

## Under Development

```bash
# Astro
pnpm dlx degit kaufmann-dev/project-templates/astro . --force --mode=tar

# Hono API
pnpm dlx degit kaufmann-dev/project-templates/hono-api . --force --mode=tar

# Hono API Finance
pnpm dlx degit kaufmann-dev/project-templates/hono-api-finance . --force --mode=tar

# Next.js
pnpm dlx degit kaufmann-dev/project-templates/nextjs . --force --mode=tar
```
