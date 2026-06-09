[Build & Test](#build--test) | [Tooling](#tooling) | [Technology Stack](#technology-stack) | [Guidelines & Examples](#guidelines--examples)

# Build & Test

This file is for reusable SvelteKit template projects. When a real project has `package.json`, `pnpm-workspace.yaml`, `drizzle.config.*`, CI, or deployment files, always derive the final commands from those files first.

Template default commands:

```bash
pnpm install
pnpm dev
pnpm check
pnpm build
pnpm test
pnpm exec vitest run
pnpm exec playwright test
pnpm drizzle-kit generate
pnpm drizzle-kit migrate
pnpm dlx shadcn-svelte@latest add <component-name>
```

Use `pnpm dev` for local development. Use `pnpm check` before finishing Svelte or TypeScript changes. Use `pnpm build` before finishing deployment, routing, server, adapter, or package changes.

Use `pnpm test` when the project defines a test script. Use `pnpm exec vitest run` only when Vitest is configured and there is no project test script. Use `pnpm exec playwright test` only when Playwright is configured or end-to-end work is part of the task.

For Drizzle schema changes, always generate and run migrations through Drizzle Kit. Keep schema files, generated migrations, and migration execution aligned with the project Drizzle config.

For shadcn-svelte components, always check whether `src/lib/components/ui/<component>/` already exists before running the CLI. Add only the components required by the current task.

# Tooling

Always use the Svelte MCP server before writing, reviewing, or refactoring Svelte or SvelteKit code:

1. Call `list-sections` to identify relevant documentation.
2. Fetch all relevant sections with `get-documentation`.
3. After writing Svelte code, run `svelte-autofixer` until it reports no issues or suggestions.
4. Generate a playground link only after the user asks for one, and only when the code was not written into the project.

Use the Svelte file-editor subagent for Svelte component or Svelte module work if you support project subagents. Use Svelte skills as workflow guidance and use the Svelte MCP server as the canonical documentation and autofix source.

Use the `shadcn-svelte` MCP server for shadcn-svelte component docs, Bits UI docs, and Lucide Svelte icon lookup. Use local component source as the final source of truth once a component has been copied into the project.

Use `playwright` only for browser automation, visual verification, or end-to-end test work. For static inspection, prefer reading files and running local checks.

# Technology Stack

- Use SvelteKit with `@sveltejs/adapter-node` for the application framework and Node deployment target.
- Use Tailwind CSS and `shadcn-svelte` for UI.
- Use `@lucide/svelte` for icons.
- Use `mode-watcher` for light, dark, and system theme mode.
- Use Drizzle with PostgreSQL for persistence.
- Use Better Auth for authentication and session management.
- Use Superforms and Zod for user-facing forms.
- Use Resend and `better-svelte-email` for email.
- Use Paraglide for internationalization.
- Use Vitest for unit and component tests.

Do not use frameworks or libraries just because they are installed. Always keep optional infrastructure out of the project until its feature is being implemented.

# Guidelines & Examples

## Svelte 5

Always treat this as a Svelte 5 project. Current Svelte documentation is the source of truth, not older training data. Assume your Svelte knowledge may be stale because Svelte 5 uses runes, snippets, fine-grained reactivity, and newer event syntax.

### Runes

Always write new Svelte code in runes mode:

- Use `$props()` for component inputs and forwarded props.
- Use `$state` only for values that must update the template, a derived value, or an effect.
- Use `$state.raw` for large objects, API responses, or arrays that are reassigned as whole values and do not need deep mutation tracking.
- Use `$derived` for computed state.
- Use `$derived.by` only when the computation cannot be expressed clearly as a single expression.
- Use `$effect` only as an escape hatch for external synchronization or unavoidable reactive observation.
- Use event handlers, component callbacks, function bindings, or direct assignment for user-driven changes.
- Use snippets and `{@render ...}` for reusable markup and component children.
- Use `onclick={...}` and other `on...` attributes for event listeners.
- Use keyed `{#each}` blocks with stable object identifiers.
- Use CSS custom properties for parent-to-child styling boundaries.
- Use `createContext` for typed context instead of unscoped shared module state when state must be per request or per tree.

Always treat props as changeable. Values derived from props should normally be `$derived`.

Prefer modern Svelte replacements:

- Use snippets and `{@render ...}` for children and reusable markup.
- Use `<DynamicComponent>` for dynamic component rendering.
- Use `import Self from "./ThisComponent.svelte"` and `<Self>` for recursive rendering.
- Use classes with `$state` fields for shared reactive logic when that fits better than stores.
- Use `{@attach ...}` for new attachment code when current Svelte docs support it.
- Use clsx-style arrays and objects in `class` attributes for conditional classes.

Use Svelte async features only when the installed Svelte version and `svelte.config.js` enable them. Await expressions and hydratable behavior require current documentation checks and the relevant experimental config when they are not stable for the project.

### Reactivity and Effects

Always use `$derived`, event handlers, function bindings, or direct assignment before reaching for `$effect`.

Use `$effect` with extra suspicion. It tracks every state read inside its closure. Reading and writing the same state in one tracked effect can trigger `ERR_SVELTE_TOO_MANY_UPDATES`.

Do not do this:

```svelte
<script lang="ts">
  let count = $state(0);

  $effect(() => {
    count = count + 1;
  });
</script>
```

Prefer direct initialization or a derived value:

```svelte
<script lang="ts">
  let count = $state(1);
  let doubled = $derived(count * 2);
</script>
```

When an effect must write state, track the external source and keep reads of the written target out of the dependency set:

```svelte
<script lang="ts">
  import { untrack } from "svelte";

  let source = $state(0);
  let target = $state(0);

  $effect(() => {
    const next = source + 1;
    untrack(() => {
      target = next;
    });
  });
</script>
```

Always use `$derived` instead of `$effect` for computed state:

```svelte
<script lang="ts">
  let count = $state(0);
  let doubled = $derived(count * 2);
</script>
```

Always react to user actions at the event boundary instead of watching the state change afterward:

```svelte
<Select
  bind:value={currentPage}
  onValueChange={(value) => navUpdate({ page: value })}
/>
```

Use function bindings for type conversion or normalization at the binding boundary:

```svelte
<Select
  bind:value={
    () => query.rowsPerPage.toString(),
    (value) => {
      query.rowsPerPage = Number.parseInt(value, 10);
    }
  }
/>
```

Always write effects as browser-only by nature; effects do not run during server rendering. Put browser setup directly in the effect and return cleanup. For global event listeners, use `<svelte:window>` or `<svelte:document>` rather than `onMount` or an effect.

Use `createSubscriber` from `svelte/reactivity` when Svelte needs to observe an external source. Use `$inspect` and `$inspect.trace(label)` for reactivity debugging; put `$inspect.trace` first inside the effect, derived value, or function being traced.

If an effect genuinely needs explicit dependency control and the project already uses `runed`, consider `watch` from `runed`. Do not add `runed` only to avoid a small refactor.

## UI, Styling, and Icons

Always use shadcn-svelte for common UI primitives. Components are source files copied into `src/lib/components/ui/`; they are not imported from a package named `shadcn-svelte`.

Always import shadcn-svelte components from local `$lib/components/ui/...` paths after they have been added to the project.

Available shadcn-svelte components include:

```text
accordion alert alert-dialog aspect-ratio avatar badge breadcrumb button calendar card carousel chart checkbox collapsible combobox command context-menu data-table date-picker dialog drawer dropdown-menu form hover-card input input-otp label menubar navigation-menu pagination popover progress radio-group range-calendar resizable scroll-area select separator sheet sidebar skeleton slider sonner switch table tabs textarea toggle toggle-group tooltip
```

Import shadcn-svelte components from `$lib/components/ui/<component>`:

```svelte
<script lang="ts">
  import { Button } from "$lib/components/ui/button";
  import { Card, CardContent, CardHeader, CardTitle } from "$lib/components/ui/card";
</script>
```

Customize shadcn-svelte components with Tailwind classes through `class`, using the local `cn()` helper when conditional class merging is needed.

Always use `@lucide/svelte` for icons:

```svelte
<script lang="ts">
  import { Search } from "@lucide/svelte";
</script>

<Search class="size-4" />
```

Always use `mode-watcher` for light, dark, and system theme behavior. Add `ModeWatcher` once in the root layout:

```svelte
<script lang="ts">
  import { ModeWatcher } from "mode-watcher";

  let { children } = $props();
</script>

<ModeWatcher />
{@render children()}
```

Use `setMode("light" | "dark" | "system")` or `toggleMode` from `mode-watcher` for controls.

## Auth, Forms, Email, and Data

Always use Better Auth for authentication and session management. Check current Better Auth documentation before implementing providers, plugins, adapters, session handling, or account flows.

Starting server pattern:

```ts
import { betterAuth } from "better-auth";

export const auth = betterAuth({
  // project config
});
```

SvelteKit hook pattern:

```ts
import { building } from "$app/environment";
import { auth } from "$lib/server/auth";
import { svelteKitHandler } from "better-auth/svelte-kit";

export async function handle({ event, resolve }) {
  return svelteKitHandler({ event, resolve, auth, building });
}
```

Client pattern:

```ts
import { createAuthClient } from "better-auth/svelte";

export const authClient = createAuthClient();
```

Server action cookie pattern:

```ts
import { getRequestEvent } from "$app/server";
import { sveltekitCookies } from "better-auth/svelte-kit";

plugins: [sveltekitCookies(getRequestEvent)];
```

Always use Superforms with Zod for user-facing forms. With shadcn-svelte form UI, follow the chain:

```text
zod schema -> superforms -> formsnap -> shadcn-svelte form components
```

Always use the current shadcn-svelte form docs before writing form markup. Use `Form.Field`, `Form.Control`, snippet props, and the shadcn form error components rather than raw ad hoc form markup.

Always use Drizzle and PostgreSQL for persistence.

Always use better-svelte-email for email templates and Resend for delivery when email is implemented. Write templates as Svelte components, render them in server-only code, and send both HTML and plain text.

Starting email rendering pattern:

```ts
import Renderer, { toPlainText } from "better-svelte-email/render";
import WelcomeEmail from "$lib/emails/welcome-email.svelte";

const renderer = new Renderer();
const html = await renderer.render(WelcomeEmail, {
  props: { name: user.name }
});
const text = toPlainText(html);
```

## Local Database and Deployment

During local development, use the manually managed Podman PostgreSQL database named `postgres-sveltekit` when the project follows this template convention. Treat production database provisioning as separate deployment infrastructure.

Always keep deployment fixes scoped to the exact failing layer. When debugging Coolify or Nixpacks failures, identify the failing command first, then fix that command or config.

For Coolify and Nixpacks:

- If `pnpm-workspace.yaml` exists in a single-package app, keep a non-empty `packages` list with `.` included.
- Use `engines.node` and `nixpacks.toml` to pin compatible Node behavior when dependencies require a minimum patch version.
- Read deployment environment variables from `process.env`.
- Load `.env` only after checking that the file exists.
- Validate seed script environment variables before calling Better Auth APIs.
- Document and enforce minimum seeded account password lengths.
- Let Nixpacks handle the install phase unless a project-specific reason requires otherwise.
- Prefer explicit deploy or runtime migration and seed steps when Coolify supports them.
- Keep build-time migration and seed scripts idempotent when they must run during image builds.