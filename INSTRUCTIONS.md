# Repository Instructions

## Build and Verification

Derive final commands from `package.json`, `pnpm-workspace.yaml`, `vite.config.ts`, and `drizzle.config.*`. Use these defaults:

```bash
pnpm install
pnpm dev                     # Local development
pnpm check                   # Run before finishing Svelte/TS changes
pnpm build                   # Run before finishing deployment/routing/server changes
pnpm test                    # If defined in package.json
pnpm exec vitest run         # If Vitest is configured without a test script
pnpm auth:schema             # Regenerate the Better Auth schema after changing auth config or plugins
pnpm drizzle-kit generate    # Generate schema migrations
pnpm drizzle-kit migrate     # Execute migrations
```

- On a fresh clone, run `pnpm dev` or `pnpm build` once before `pnpm check`. Paraglide generates the gitignored `src/lib/paraglide` directory through its Vite plugin.
- Always generate and run migrations through Drizzle Kit. Keep schema files and migrations aligned with the project config.

## Tooling

- **Svelte MCP**: Use before writing, reviewing, or refactoring Svelte or SvelteKit code.
  - Call `list-sections` to identify relevant documentation.
  - Fetch all relevant sections with `get-documentation`.
  - After writing Svelte code, run `svelte-autofixer` until it reports no issues or suggestions.
  - Generate a playground link only after the user asks for one, and only when the code was not written into the project.
- **Svelte file-editor**: Use this subagent for Svelte component/module work if available.

## Technology Stack

- **Framework**: SvelteKit 3 with `@sveltejs/adapter-node`
- **UI**: Tailwind CSS and `shadcn-svelte`
- **Icons**: `@lucide/svelte`
- **Theme**: `mode-watcher`
- **Database**: Drizzle with PostgreSQL
- **Auth**: Better Auth
- **Forms**: SvelteKit remote functions (`form`) and Zod
- **Email**: Resend and `better-svelte-email`
- **i18n**: Paraglide
- **Testing**: Vitest

Do not use frameworks or libraries just because they are installed. Keep optional infrastructure out of the project until its feature is being implemented.

## SvelteKit 3 Conventions

This is a SvelteKit 3 project. Do not use SvelteKit 2 APIs.

- **Config**: There is no `svelte.config.js`. Configure SvelteKit and the Svelte compiler through the `sveltekit({ ... })` plugin options in `vite.config.ts`. `compilerOptions.experimental.async` and `experimental.remoteFunctions` are enabled.
- **`#lib`**: Import from `src/lib` with `#lib/...` (declared in `package.json` `imports`), including the file extension, e.g. `#lib/server/db/index.ts` or `#lib/utils.js`. `$lib` does not exist.
- **Environment**: Declare variables in `src/env.ts` with `defineEnvVars` from `@sveltejs/kit/env`, then import them from `$app/env/private` or `$app/env/public`. Use `browser`, `building`, `dev`, and `version` from `$app/env`. Do not use `$env/*` or `$app/environment`.
- **State and navigation**: Use `$app/state`, never `$app/stores`. Use `refreshAll` instead of `invalidateAll`, and `goto(url, { shallow: true, state })` instead of `pushState`/`replaceState`. `page.url` is read-only; copy it with `new URL(page.url.href)` before changing it.
- **Paths**: Use `resolve` and `asset` from `$app/paths`, without a leading `/` for pathnames and assets (e.g. `resolve('blog/hello')`, `asset('logo.png')`). Route IDs keep the leading `/`.
- **Types**: Import `Handle` and other hook types from `@sveltejs/kit/hooks`, param matcher helpers from `@sveltejs/kit/params`, and remote function types from `$app/server`.
- **Errors and responses**: Call `error(status, message, extra?)` with a string message. Pass `{ external: true }` (or an origin list) to `redirect` for external URLs. Use `Response.json(...)` instead of the deprecated `json(...)`.
- **Param matchers**: Declare all matchers in `src/params.ts` with `defineParams`; there is no `src/params/` directory.
- **Server-only code**: Any `server` directory outside `src/routes` and any file with a `server` segment (e.g. `db.server.ts`, `server.ts`) is server-only.

## Svelte Implementation Patterns

Always treat this as a Svelte 5 project. Use runes, snippets, and fine-grained reactivity.

### Core State and Props

- Use `$props()` for component inputs. Always treat props as changeable.
- Use `$state` only for values that must update the template, a derived value, or an effect.
- Use `$state.raw` for large objects, API responses, or arrays that are reassigned entirely without deep mutation tracking.
- Use `$derived` for computed state, including values derived from props.
- Use `$derived.by` only when computation requires a multi-line function.

### Reactivity and Effects ($effect)

Never use `$effect` unless absolutely necessary (e.g., syncing with external non-Svelte libraries). Using `$effect` is almost always a sign the code should be refactored.

**❌ Wrong: `$effect` for computed state**
```svelte
let rowsPerPageValue = $state(String(data.query.rows));
$effect(() => {
  rowsPerPageValue = String(data.query.rows);
});
```

**✅ Right: Use `$derived`**
```svelte
let rowsPerPageValue = $derived(String(data.query.rows));
```

**❌ Wrong: `$effect` to react to state changes**
```svelte
let currentPage = $state(data.query.page);
$effect(() => {
  navUpdate({ page: currentPage });
});
<Select bind:value={currentPage} />
```

**✅ Right: React to events at the boundary**
```svelte
let currentPage = $state(data.query.page);
<Select
  bind:value={currentPage}
  onValueChange={(value) => navUpdate({ page: value })}
/>
```

**❌ Wrong: `$effect` for type conversion with `bind:`**
```svelte
let query = $state({ rowsPerPage: 10 });
let rowsPerPageValue = $state(String(query.rowsPerPage));
$effect(() => {
  const n = Number.parseInt(rowsPerPageValue, 10);
  if (!Number.isFinite(n) || n === query.rowsPerPage) return;
  query.rowsPerPage = n;
});
<Select bind:value={rowsPerPageValue} />
```

**✅ Right: Use getter/setter bindings**
```svelte
let query = $state({ rowsPerPage: 10 });
<Select
  bind:value={
    () => query.rowsPerPage.toString(),
    (value) => { query.rowsPerPage = Number.parseInt(value, 10); }
  }
/>
```

**Valid `$effect` Escape Hatch:**
When an effect must write state, track the external source and keep reads of the written target out of the dependency set using `untrack`:

```svelte
import { untrack } from "svelte";

let source = $state(0);
let target = $state(0);

$effect(() => {
  const next = source + 1;
  untrack(() => { target = next; });
});
```

Always write effects as browser-only by nature. For global event listeners, use `<svelte:window>` or `<svelte:document>` rather than `onMount` or an effect.

Use `createSubscriber` from `svelte/reactivity` to observe external sources. Use `$inspect.trace(label)` as the first line of a reactive block to debug update triggers.

If an effect genuinely needs explicit dependency control and the project uses `runed`, consider `watch`. Do not add `runed` only to avoid a small refactor.

### Component Architecture & Styling

Use modern Svelte replacements over legacy features:

- Use snippets and `{@render ...}` for reusable markup and component children.
- Use `<DynamicComponent>` for dynamic component rendering.
- Use `import Self from "./ThisComponent.svelte"` and `<Self>` for recursive rendering.
- Use classes with `$state` fields for shared reactive logic when it fits better than stores.
- Use `{@attach ...}` for new attachment code.
- Use `clsx`-style arrays and objects in `class` attributes for conditional classes.
- Use `onclick={...}` and other `on...` attributes for event listeners.
- Use keyed `{#each}` blocks with stable object identifiers. Never use the index as a key. Avoid destructuring if mutating the item.
- Use CSS custom properties for parent-to-child styling boundaries.
- Use `createContext` for typed context instead of unscoped shared module state when state must be per request or per tree.
- Use `await` expressions and `hydratable` where they simplify data loading; `compilerOptions.experimental.async` is already enabled in `vite.config.ts`.

### Legacy Features to Avoid in New Code

Avoid these legacy Svelte features in new or refactored code:

- `export let`, `$$props`, `$$restProps`
- `$: ` reactive blocks or assignments
- `<slot>`, `$$slots`, `<svelte:fragment>`
- `<svelte:component>` and `<svelte:self>`
- `use:action`
- `class:` directives
- `on:` event attributes (e.g., `on:click`)

## UI and Styling

- **shadcn-svelte**: All components are already pre-installed in `src/lib/components/ui/`. **Never run the CLI to install components, and never delete unused shadcn components during codebase cleanup.**
  - Never import components from a package named `shadcn-svelte`.
  - Import them only from local `#lib/components/ui/...` paths (e.g. `#lib/components/ui/button/index.js`).
  - Use local component source as the final source of truth once a component has been copied into the project.
  - Customize with Tailwind classes using `class` and the local `cn()` helper.
- Available shadcn-svelte components: `accordion alert alert-dialog aspect-ratio attachment avatar badge breadcrumb bubble button button-group calendar card carousel chart checkbox collapsible command context-menu dialog drawer dropdown-menu empty field hover-card input input-group input-otp item kbd label marker menubar message native-select navigation-menu pagination popover progress radio-group range-calendar resizable scroll-area select separator sheet sidebar skeleton slider sonner spinner switch table tabs textarea toggle toggle-group tooltip`. Build comboboxes from `popover` + `command`, date pickers from `popover` + `calendar`, and data tables from `table`. The `form` component is intentionally not installed.
- **Icons**: Always use `@lucide/svelte` (e.g., `<Search class="size-4" />`).
- **Theming**: Use `setMode("light" | "dark" | "system")` or `toggleMode` from `mode-watcher` for controls. Add `ModeWatcher` once in the root layout:
  ```svelte
  <script lang="ts">
    import { ModeWatcher } from "mode-watcher";
    let { children } = $props();
  </script>
  <ModeWatcher />
  {@render children()}
  ```
- **Visual rules**: They live in `src/routes/layout.css`: tokens, `--radius`, and a base-layer reset. Use the theme tokens (`bg-background`, `text-muted-foreground`, `border-border`, ...) and `rounded-*` utilities instead of hardcoded colors or radii.
  - The reset zeroes drop shadows and focus rings, disables transitions and animations, and draws keyboard focus as a 2px outline. Do not add `shadow-*`, transitions, decorative animation, or custom focus rings. Only `animate-spin` indicators move.
  - Mark surface edges with `border` or the `ring-1` that shadcn components already use.
  - Use color only to convey hierarchy, state, or category, and never as the only signal.
- **Template helpers** (not shadcn components, kept in `src/lib/components/`):
  - `#lib/components/choice-group/index.js` (`ChoiceGroup.Root` and `ChoiceGroup.Item`) builds single-choice option groups. Use it instead of raw `ToggleGroup`. It keeps exactly one option selected.
  - `INPUT_SURFACE` from `#lib/components/input-surface.js` gives controls that act like form fields (toggles, select-style triggers) the same fill as `Input`. Combine it with a base style that has no `dark:` background overrides, such as `buttonVariants({ variant: "secondary" })`.
- `src/lib/components/ui` is generated vendor code and is excluded from ESLint.

## Backend and Services

- **Authentication**: Check current Better Auth documentation before implementing providers, plugins, adapters, session handling, or account flows.
  - *Server*: `export const auth = betterAuth({ ... });`
  - *Setup*: `sv` generated the server instance in `#lib/server/auth.ts` and the session hook in `src/hooks.server.ts`. Extend those files instead of creating new ones.
  - *Hook*: `return svelteKitHandler({ event, resolve, auth, building });` with `building` from `$app/env`.
  - *Client*: `export const authClient = createAuthClient();`
  - *Cookies*: `plugins: [sveltekitCookies(getRequestEvent)]`
- **Forms**: Always use remote functions with Zod. Follow the chain: `zod schema -> form(...) in a .remote.ts file -> shadcn-svelte field components`. Do not use Superforms, formsnap, or form actions for new forms.
  - Spread the form onto `<form {...myForm}>` and every control's attributes from `myForm.fields.<name>.as('<type>')`. Never set `name` manually; submissions without `.as(...)` attributes are rejected.
  - Render issues with `Field.Error errors={myForm.fields.<name>.issues()}` and mark invalid fields with `data-invalid`.
  - Export shared schemas from a regular module (not the `.remote.ts` file) when the client needs them for `myForm.preflight(schema)`.
  ```ts
  // src/routes/newsletter.remote.ts
  import { form } from "$app/server";
  import { z } from "zod";

  export const subscribe = form(z.object({ email: z.email() }), async ({ email }) => {
    // ...
  });
  ```
  ```svelte
  <script lang="ts">
    import * as Field from "#lib/components/ui/field/index.js";
    import { Input } from "#lib/components/ui/input/index.js";
    import { Button } from "#lib/components/ui/button/index.js";
    import { subscribe } from "./newsletter.remote";
  </script>

  <form {...subscribe}>
    <Field.Field data-invalid={!!subscribe.fields.email.issues()}>
      <Field.Label for="email">Email</Field.Label>
      <Input id="email" {...subscribe.fields.email.as("email")} />
      <Field.Error errors={subscribe.fields.email.issues()} />
    </Field.Field>
    <Button type="submit" disabled={!!subscribe.pending}>Subscribe</Button>
  </form>
  ```
- **Email**: Use `better-svelte-email` for templates and Resend for delivery. Render components in server-only code, and send both HTML and plain text.
  ```ts
  import Renderer, { toPlainText } from "better-svelte-email/render";
  const html = await new Renderer().render(EmailTemplate, { props });
  const text = toPlainText(html);
  ```

## Local Database and Deployment

- **Database**: Use the manually managed Podman PostgreSQL database named `postgres-sveltekit` for local development. Treat production database provisioning as separate infrastructure.
- **Debugging**: Keep deployment fixes scoped to the exact failing layer. Identify the failing command first in Coolify or Nixpacks before fixing it.

For Coolify and Nixpacks:
- If `pnpm-workspace.yaml` exists in a single-package app, keep a non-empty `packages` list with `.` included.
- Use `engines.node` and `nixpacks.toml` to pin compatible Node behavior when dependencies require a minimum patch version. SvelteKit 3 requires Node 22.17 or newer.
- In app code, read environment variables through `src/env.ts` and `$app/env/*`. In standalone scripts (seeds, migrations), read `process.env` and load `.env` only after checking that the file exists.
- `adapter-node` no longer reads `ORIGIN`. Behind Coolify's reverse proxy, set `PROTOCOL_HEADER=x-forwarded-proto` and `HOST_HEADER=x-forwarded-host`, or set `paths.origin` in the `sveltekit()` options. `ORIGIN` remains the Better Auth base URL.
- Validate seed script environment variables before calling Better Auth APIs.
- Document and enforce minimum seeded account password lengths.
- Let Nixpacks handle the install phase unless a project-specific reason requires otherwise.
- Prefer explicit deploy or runtime migration and seed steps when Coolify supports them.
- Keep build-time migration and seed scripts idempotent when they must run during image builds.
