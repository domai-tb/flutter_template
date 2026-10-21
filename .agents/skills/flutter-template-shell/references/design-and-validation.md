# Preserve the template's design and interactions

Use this guidance for layout and shell changes in any consuming application. Take exact values and behavior from current source and the application's active design requirements; this reference does not freeze a temporary redesign or CI policy.

## Theme and geometry

- `lib/core/themes.dart` defines `AppShellSpacing`, `AppShellMetrics`, `AppShellTokens`, and `AppTheme.metrics(context, phone: ...)`. Use the existing compact, comfortable, and touch metrics rather than independent per-page dimensions.
- Use theme colors, text styles, spacing, and state colors for surfaces, focus, hover, selection, and disabled content. Inspect an existing shared control before adding a variant.
- Preserve the shell's fully bordered, rounded navigation, main workspace, and right-sidebar surfaces. `HomePage._shellSurface` currently owns the outer treatment; do not add a competing outer frame in every feature page. Match the relevant control or surface, since outer shell corners and inner control corners need not use the same radius.
- Align toolbar icon centers and control bounds, not just font baselines. Use metric-defined row, tab, target, and control heights; keep repeated gaps consistent. Preserve visible focus and adequate touch targets when adapting dense desktop controls.
- Layout feature content against its actual constraints with `LayoutBuilder`. A page inside a split or beside panels has less width than the application window. Keep overflowing content scrollable and supply readable loading, empty, unavailable, and error states; `ShellContentSlot` is available for these shell slot states.

## Responsive behavior

Inspect `HomePage.build`, `_isPhoneLayout`, and `widgets/shell_split_view.dart` when changing adaptation. The current shell chooses phone navigation on Android/iOS, and on web below 600 logical pixels; desktop window width alone does not select the phone branch. Activity panels are available from 800, and the right sidebar docks from 1200; narrower layouts use its end drawer. Split panes adapt to their available width and declared minimum widths.

Prefer extending these shared decisions when required. Do not introduce contradictory page-level shell navigation or discard a tab's state when a breakpoint is crossed. Keep essential utility destinations reachable in mobile navigation.

## Input, identity, and accessibility

- Preserve tab add, rename, close, reorder, restore, and open-tab search behavior. Keep sidebar destination order/hide preferences separate from tab order and the page's internal navigation hierarchy.
- New controls need keyboard focus/activation, localized accessible labels or tooltips, and pointer/touch behavior appropriate to their layout. Integrate shortcuts with the existing `Shortcuts`/`Actions` and focus handling; avoid intercepting normal text editing.
- Key repeated/reorderable items by stable identity. Each mounted tab owns its focus nodes, animation controllers, scroll controllers, and `GlobalKey`s. Avoid moving a single stateful subtree between two simultaneously mounted locations.
- Preserve system text scaling and semantics. Announce meaningful changes through the existing shell semantics/live-region path where appropriate. Do not disable semantics, remove reorderable behavior, or filter framework exceptions to hide an interaction bug.
- For rebuild, tooltip, focus, or semantics failures, reproduce the triggering transition with accessibility enabled. Check identity, resource ownership, and lifecycle across hover, reordering, route changes, and tab switching before changing visible behavior.

## Verify the behavior that changed

Use the project's pinned SDK through FVM and follow repository command wrappers. Run analysis and focused unit/widget tests appropriate to the change. Choose relevant checks from the following; do not expand every small change into a complete shell test matrix.

| Changed contract | Useful observable check |
| --- | --- |
| Registration/navigation | Registered view opens in an allowed destination; cross-section commands preserve the target workspace |
| Tab identity/state | Two instances retain different local state; rename, close, reorder, and return to a destination work |
| Restoration | Existing saved preferences still load; reconstructed tabs show matching feature state and hierarchy |
| Breadcrumb/sidebar/status | Menu activation changes content; sidebar honors explicit requests and later close; active-tab contributions switch correctly |
| Split panes | Minimum widths, resizing, collapsed selection, and restoration behave without overflow |
| Geometry/responsiveness | Measure icon centers, repeated gaps, control/tab bounds, density, and widths around affected breakpoints |
| Input/accessibility | Pointer hover, keyboard, touch, text scaling, focus, and semantics remain usable without exceptions |

Use runtime screenshots at application-specified viewports for visual inspection when changing layout. Record the viewport, platform, theme, and density. Diagnostic screenshots are not golden baselines. Follow the consuming project's current golden-test policy; retain existing tests/images and change baselines only for an authorized intentional visual change, never merely to make an unexpected comparison pass.

For runtime investigation attach to the application's existing device/session when available. Distinguish debug cold-start or emulator performance messages from reproduced navigation failures; use profiling when making performance claims. Report what was actually verified and any unresolved limitation.
