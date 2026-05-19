## ⚠️ Important: Your Svelte Knowledge Is Outdated

Svelte 5 introduced a fundamentally new paradigm — runes, snippets, fine-grained reactivity — that is a breaking departure from Svelte 4. Your training data almost certainly reflects Svelte 4 patterns (e.g. `$:`, `export let`, slots, stores) which are either deprecated or behave differently in Svelte 5. **Do not rely on your training data for any Svelte or SvelteKit code.** Always use the MCP tools below to retrieve current documentation before writing or reviewing any Svelte code.

---

## MCP Servers

Use project-scoped MCP configuration when your agent tool supports it. Do not put secrets directly in MCP config files; reference environment variables instead.

- `svelte` is enabled. Use it for current Svelte 5 and SvelteKit documentation and autofixing.
- `shadcn-svelte` is enabled. Use it for shadcn-svelte component documentation, Bits UI documentation, and Lucide Svelte icon lookup.
- `playwright` is optional. Use it only when browser automation or end-to-end test work is required.
- `postgres` is optional and requires `DATABASE_URL`.
- `resend` is optional and requires `RESEND_API_KEY`.
- `glitchtip` is optional and requires `GLITCHTIP_MCP_URL`.

Do not add optional MCP servers by default in tools that cannot safely keep MCP entries disabled. Prefer only the default `svelte` and `shadcn-svelte` servers unless the optional feature is actually needed.

No MCP server is configured for Tailwind CSS, Iconify, mode-watcher, Better Auth, better-svelte-email, Superforms, Zod, Paraglide, Plausible, or Drizzle because no official or high-confidence project MCP server was identified for normal template use. Use the installed skills and the current package documentation instead.

## Svelte Subagents

Use the Svelte file-editor subagent for Svelte component or Svelte module work when your agent tool supports project subagents.

Keep the Svelte skills in `.agents/skills`. The Svelte MCP server is the canonical source for documentation and autofixing; the Svelte skills provide on-demand workflow instructions and CLI fallback guidance.

---

You are able to use the Svelte MCP server, where you have access to comprehensive Svelte 5 and SvelteKit documentation. Here's how to use the available tools effectively:

## Available Svelte MCP Tools:

### 1. list-sections

Use this FIRST to discover all available documentation sections. Returns a structured list with titles, use_cases, and paths.

When asked about Svelte or SvelteKit topics, ALWAYS use this tool at the start of the chat to find relevant sections.

### 2. get-documentation

Retrieves full documentation content for specific sections. Accepts single or multiple sections.

After calling the list-sections tool, you MUST analyze the returned documentation sections (especially the use_cases field) and then use the get-documentation tool to fetch ALL documentation sections that are relevant for the user's task.

### 3. svelte-autofixer

Analyzes Svelte code and returns issues and suggestions.

You MUST use this tool whenever writing Svelte code before sending it to the user. Keep calling it until no issues or suggestions are returned.

### 4. playground-link

Generates a Svelte Playground link with the provided code.

After completing the code, ask the user if they want a playground link. Only call this tool after user confirmation and NEVER if code was written to files in their project.


---

## How to Use shadcn-svelte

> **shadcn-svelte components are not imported from a package.** Do not import from `'shadcn-svelte'`. Components are added individually via CLI and copied directly into the project source code. If you try to import from the package name you will get an error.

### The Mental Model

shadcn-svelte is a CLI that writes component source files into `src/lib/components/ui/` in the project. Once added, a component is just a `.svelte` file you own — it lives in the codebase, not in `node_modules`.

### Adding a Component

Before using any shadcn-svelte component, it must first be added to the project. Always check whether `src/lib/components/ui/<component>/` already exists. If it does not:

```bash
pnpm dlx shadcn-svelte@latest add <component-name>
# Example: pnpm dlx shadcn-svelte@latest add button
# Multiple at once: pnpm dlx shadcn-svelte@latest add button card input label
```

### Importing Components

After adding, always import from the `$lib` alias — never from a package name:

```svelte
<!-- ✅ Correct -->
import { Button } from '$lib/components/ui/button';
import { Card, CardContent, CardHeader, CardTitle } from '$lib/components/ui/card';
import { Input } from '$lib/components/ui/input';

<!-- ❌ Wrong — this package path does not exist -->
import { Button } from 'shadcn-svelte';
```

Many components export multiple named sub-components (e.g. `Card` exports `Card`, `CardHeader`, `CardContent`, `CardFooter`, `CardTitle`, `CardDescription`). Import all the parts you need from the same path.

### Styling

Customise components by passing Tailwind classes via the `class` prop. Use the `cn()` utility from `$lib/utils` to merge classes:

```svelte
import { cn } from '$lib/utils';

<Button class={cn('w-full mt-4', someCondition && 'opacity-50')}>Submit</Button>
```

### Forms

The `form` component from shadcn-svelte is built on top of **formsnap** and integrates directly with **superforms**. When building forms, always combine: `superforms` (form state) + `zod` (schema) + shadcn-svelte `form` components (UI). Do not build form UI from raw HTML inputs.

### Never Recreate What Exists

If a shadcn-svelte component covers your use case, you **must** use it. Do not write a custom button, input, dialog, dropdown, etc. from scratch. Check the available component list below first.

### Available Components

Add any of these by name with the CLI:

`accordion` `alert` `alert-dialog` `aspect-ratio` `avatar` `badge` `breadcrumb` `button` `calendar` `card` `carousel` `chart` `checkbox` `collapsible` `combobox` `command` `context-menu` `data-table` `date-picker` `dialog` `drawer` `dropdown-menu` `form` `hover-card` `input` `input-otp` `label` `menubar` `navigation-menu` `pagination` `popover` `progress` `radio-group` `range-calendar` `resizable` `scroll-area` `select` `separator` `sheet` `sidebar` `skeleton` `slider` `sonner` `switch` `table` `tabs` `textarea` `toggle` `toggle-group` `tooltip`

---

## How to Use @iconify/tailwind4

> **Do not use `@iconify/svelte`.** Do not import `<Icon icon="..." />`. This project uses the Tailwind CSS plugin, so icons are CSS classes on plain elements.

Use an inline element with an Iconify dynamic class:

```svelte
<span class="icon-[lucide--search] size-4" aria-hidden="true"></span>
<span class="icon-[mdi-light--home] size-5" aria-hidden="true"></span>
```

The class format is `icon-[collection--icon-name]`. The separator between collection and icon name is **two hyphens**. Size and color come from normal Tailwind classes (`size-4`, `text-muted-foreground`, etc.).

If the plugin is not configured yet, add it to the Tailwind CSS entry file:

```css
@plugin "@iconify/tailwind4";
```

---

## How to Use better-auth

> **Do not use Auth.js, Lucia, custom session tables, or hand-rolled auth helpers.** This project standardises on `better-auth` for authentication and session management.

Server auth should be created with `betterAuth`:

```ts
import { betterAuth } from "better-auth";

export const auth = betterAuth({
  // project config here
});
```

In SvelteKit, mount Better Auth through `hooks.server.ts` with `svelteKitHandler`:

```ts
import { building } from "$app/environment";
import { auth } from "$lib/server/auth";
import { svelteKitHandler } from "better-auth/svelte-kit";

export async function handle({ event, resolve }) {
  return svelteKitHandler({ event, resolve, auth, building });
}
```

For client-side auth actions, create the Svelte client from `better-auth/svelte`:

```ts
import { createAuthClient } from "better-auth/svelte";

export const authClient = createAuthClient();
```

When using auth from server actions, include the SvelteKit cookies plugin as the last Better Auth plugin:

```ts
import { getRequestEvent } from "$app/server";
import { sveltekitCookies } from "better-auth/svelte-kit";

plugins: [sveltekitCookies(getRequestEvent)]
```

Always check the current Better Auth documentation before writing authentication logic, including providers, plugins, database adapters, or session handling. Its API is not interchangeable with older SvelteKit auth libraries.

---

## How to Use better-svelte-email

> **Do not write raw HTML email strings and do not use `react-email`.** Email templates must be Svelte components rendered with `better-svelte-email`.

Create email templates as `.svelte` components, then render them on the server:

```ts
import Renderer, { toPlainText } from "better-svelte-email/render";
import WelcomeEmail from "$lib/emails/welcome-email.svelte";

const renderer = new Renderer();
const html = await renderer.render(WelcomeEmail, {
  props: { name: user.name }
});
const text = toPlainText(html);
```

Send the rendered `html` and `text` through Resend. Keep email rendering in server-only code.

---

## How to Use superforms

Use `superforms` for every user-facing form, with `zod` schemas for validation. For SvelteKit server code, validate with the Superforms adapter for Zod. For Svelte components, initialize form state with `superForm` and Svelte 5 runes-compatible patterns from the current docs.

When using shadcn-svelte forms, the chain is:

```text
zod schema → superforms → formsnap → shadcn-svelte form components
```

Do not build old Svelte 4-style forms by destructuring `$form` and `$errors` into raw HTML inputs. In shadcn-svelte UI, pass the Superforms object into shadcn `Form.Field`, use `Form.Control`, render the provided snippet props, and display errors with the shadcn form error components.

Use the current shadcn-svelte form docs as the source of truth for component structure before writing form markup.

---

## How to Use mode-watcher

Use `mode-watcher` for light/dark mode. Add `ModeWatcher` once in the root layout:

```svelte
<script lang="ts">
  import { ModeWatcher } from "mode-watcher";

  let { children } = $props();
</script>

<ModeWatcher />
{@render children()}
```

Use `setMode("light" | "dark" | "system")` or `toggleMode` from `mode-watcher` for controls. Do not write custom localStorage theme code.

---

## Drizzle Workflow

Use Drizzle for database access and migrations. After schema changes, generate and run migrations with Drizzle Kit (`drizzle-kit generate`, then `drizzle-kit migrate`) instead of hand-writing migration state.

## Development Database

During development, use the manually managed Docker PostgreSQL database named `postgres-sveltekit`.

Do not turn the local Docker command into production deployment guidance. Production deployment and database provisioning are handled separately through Coolify.

---

## Technology Stack

### Always Use

These packages are part of the core infrastructure and must always be used. Never substitute them with alternatives.

| Area      | Package(s)                            | Notes                                                                |
| --------- | ------------------------------------- | -------------------------------------------------------------------- |
| Framework | `sveltekit`, `@sveltejs/adapter-node` | All projects use SvelteKit with the Node adapter                     |
| Styling   | `tailwindcss`, `shadcn-svelte`        | Use shadcn-svelte components and Tailwind utility classes for all UI |
| Icons     | `@iconify/tailwind4`                  | Use Iconify for all icons via the Tailwind plugin                    |
| Theme     | `mode-watcher`                        | Use for light/dark mode management                                   |
| Database  | `postgresql`, `drizzle`               | Drizzle ORM with PostgreSQL for all data persistence                 |
| Auth      | `better-auth`                         | Use for all authentication and session management                    |

### Use Only When Needed

These packages are not required in every project. **Do not add them unless the feature they support is actually being implemented.** However, if you do implement that feature, you **must** use the specified package — do not use alternatives.

| Feature                  | Package(s)                      | When to use                                                                                                                 |
| ------------------------ | ------------------------------- | --------------------------------------------------------------------------------------------------------------------------- |
| Forms & Validation       | `superforms`, `zod`             | Any time you build a user-facing form. Use Superforms for form handling and Zod for schema validation.                      |
| Email                    | `resend`, `better-svelte-email` | Any time the app sends emails. Use Resend as the email provider and better-svelte-email to build email templates in Svelte. |
| Internationalisation     | `paraglide`                     | Only if the app needs to support multiple languages.                                                                        |
| Unit / Component Testing | `vitest`                        | Only if unit or component tests are required.                                                                               |
| End-to-End Testing       | `playwright`                    | Only if end-to-end tests are required.                                                                                      |
| Analytics                | `plausible`                     | Only if user analytics are required.                                                                                        |
| Error Monitoring         | `glitchtip`                     | Only if error tracking and observability are required.                                                                      |
