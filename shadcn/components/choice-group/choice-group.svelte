<script lang="ts">
	import type { Snippet } from 'svelte';
	import * as ToggleGroup from '#lib/components/ui/toggle-group/index.js';

	let {
		value,
		onValueChange,
		size = 'default',
		class: className,
		children,
		...restProps
	}: {
		value: string;
		onValueChange: (value: string) => void;
		size?: 'sm' | 'default';
		class?: string;
		children: Snippet;
		'aria-label': string;
	} = $props();
</script>

<!-- Exactly one option stays selected: clicking the selected item does not clear it. -->
<ToggleGroup.Root
	type="single"
	{size}
	variant="outline"
	bind:value={() => value, (next) => next && onValueChange(next)}
	class={className}
	{...restProps}
>
	{@render children()}
</ToggleGroup.Root>
