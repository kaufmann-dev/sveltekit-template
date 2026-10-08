<script lang="ts">
	import type { ToggleGroup as ToggleGroupPrimitive } from 'bits-ui';
	import { INPUT_SURFACE } from '#lib/components/input-surface.js';
	import * as ToggleGroup from '#lib/components/ui/toggle-group/index.js';
	import { cn } from '#lib/utils.js';

	let { class: className, ...restProps }: ToggleGroupPrimitive.ItemProps = $props();
</script>

<ToggleGroup.Item
	class={cn(
		INPUT_SURFACE,
		'not-last:not-data-[state=on]:border-r-border group-data-[spacing=0]/toggle-group:px-3 data-[state=on]:bg-primary data-[state=on]:text-primary-foreground data-[state=on]:hover:bg-primary data-[state=on]:hover:text-primary-foreground',
		className
	)}
	{...restProps}
/>
