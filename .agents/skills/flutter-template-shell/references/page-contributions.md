# Publish page contributions

All controllers below come from the owning page's `ShellViewContext view`. They are scoped to a tab and owned by the shell. Source: `lib/pages/home/page_navigator.dart`; renderers and lifecycle wiring live in `lib/pages/home/home_page.dart` and `widgets/`.

## Hierarchical navigation and breadcrumbs

Publish the page's hierarchy with `ShellNavigationNode(id:, label:, parentId:, onActivate:, children:, childrenProvider:)` and `view.breadcrumbs`:

- `registerNode`/`registerNodes` make nodes available without replacing the active path.
- `setPath(Iterable<ShellNavigationNode>)` registers those path nodes and selects the path.
- `getChildren(id)` resolves static children, registered nodes with that `parentId`, and optional asynchronous `childrenProvider` results.
- `navigateTo(id)` invokes the registered node's activation callback and selects its ancestor path unless that callback already changed the path.
- `activePathIds` exposes the IDs restored with the tab. `unregisterNode(id)` removes that node and descendants registered through parent IDs.

Use stable, unique node IDs within the tab, localized labels, and parent relationships for every hierarchy level. A node's `onActivate` must also select/load the actual page content; breadcrumb state alone does not navigate feature UI. Register the parent chain before navigating to a deep node. For lazy hierarchies, resolve the relevant ancestors/children before selecting a saved leaf.

On initialization, reconstruct a valid saved path and its matching feature selection; choose a default only if that path is absent or unavailable. Publish localized labels again when locale changes without changing IDs or resetting selection. Do not assume registering a tree automatically restores feature data.

The shell renders the active path in the bottom bar and opens hierarchical menus from breadcrumb text. Use this controller instead of creating a second bottom navigation tree. `lib/pages/page1/page1_page.dart` is an example to inspect, not a business model to copy.

## Right sidebar

Use the canonical `view.rightSidebar` API:

```dart
view.rightSidebar
  ..setSelection(selectionLabel)
  ..setSections([
    ShellRightSidebarSection(
      id: 'feature.details',
      title: detailsTitle,
      builder: buildDetails,
    ),
  ]);
view.rightSidebar.focusSection('feature.details');
```

Here labels and `WidgetBuilder buildDetails` come from the page's current presentation state. Section IDs must be nonempty and unique. `setSections` replaces the page's section collection. `focusSection(id)` opens the sidebar and requests that section's expansion/scrolling; register it first.

Use `open()`, `close()`, or `setVisible(isVisible: true/false/null)`. Null clears the tab override and inherits the section/application preference. Publishing content does not require reopening the panel on every state update. Open it for an intentional page request and preserve a user's later close choice during routine rebuilds or restoration.

The shell handles docking at wide widths and an end drawer at narrower widths. A page should not own a second drawer or reach into `HomePage` state. New code uses `ShellRightSidebarSection`, `ShellRightSidebarController`, and `rightSidebarBuilder`; the `ShellInspector*`/`inspector*` names remain compatibility aliases or fields.

When sections do not fit the content, `rightSidebarBuilder` is available on the view registration, destination, and shell configuration. Current precedence is page sections → view registration builder → destination builder → application builder → shell default. Clear page sections with `setSections([])` if a builder should take over.

## Toolbar actions and commands

Use `view.toolbar.setActions(List<ShellViewAction>)` for dynamic actions of the active tab. Each action has a stable unique `id`, localized `label`, optional `icon`, and `VoidCallback onPressed`. An empty list clears dynamic actions.

`ShellViewRegistration.toolbarActionsBuilder` supplies registration-level actions, followed by controller actions in the current shell. Avoid duplicate IDs/actions. Call use cases from callbacks and reflect asynchronous results in presentation state.

Add app-level command-palette entries through `ShellConfig.commands` with `ShellCommandRegistration(id:, title:, run:)`. Do not implement a second palette. Existing top-bar tab search spans all open workspaces; it is distinct from a feature's own data search.

## Destination panels, utilities, and modules

`ShellDestination.panelBuilder` supplies its activity panel; it is separate from tab content and the right sidebar. Use `onSelected` for a destination-selection callback, or `openViewId`/`commandId` for the existing selection actions when those match the requirement. The latter IDs must resolve to registrations in the same configuration.

Use `isUtility`, `lockedVisible`, and `showOnMobile` to express destination placement/visibility through the existing navigation renderers. The IDs `settings` and `profile` have built-in utility handling in `HomePage`; preserve their roles instead of reusing those IDs for unrelated content.

For applications that need context/module selection, `ShellConfig.modules` contains `ShellModule(id:, title:, builder:)` entries; `ShellConfig.contexts` contains `ShellContext(id:, title:, modules:)` groups. The shell generates view IDs `module.<moduleId>` and `module.<contextId>.<moduleId>` for them. Keep these IDs stable and avoid duplicate manual registrations. Use explicit `ShellViewRegistration` entries with `viewBuilder` when content needs the full tab-scoped contract.

## Status and notifications

Publish persistent context/status through `view.status.setItem(ShellStatusItem(...))`, `setItems(...)`, and `removeItem(id)`. Use nonempty unique IDs and supply a localized `label`. Optional fields include `icon`, `priority`, `severity`, `tooltip`, `onTap`, `isVisible`, `progress`, and `detailsBuilder`. Progress is presented as a completion fraction; use values from 0 to 1. Prefer meaningful status changes over polling on every frame.

For other lifetimes:

| Scope | Registration |
| --- | --- |
| View instance | `ShellViewRegistration.statusProviderFactory(instanceId)` |
| Destination | `ShellDestination.statusItemsBuilder` or `statusProvider` |
| Application | `ShellConfig.globalStatusProviders` |

Providers extend `ShellStatusProvider`, return `items`, and notify listeners when they change. The shell creates and disposes providers returned by `statusProviderFactory` per tab: return a new provider, not a shared singleton that another tab still uses. Keep shared providers owned by application/destination composition and release subscriptions according to that lifetime. The shell renders the combined status and overflow behavior; do not build another status bar inside each page.

For event notifications use `AppScope.of(context).services.shellNotifications.add(severity:, title:, message:, contextId:, onAction:)`. `ShellNotificationService` is a bounded in-memory notification center; it is not a durable event log or a feature data store. Keep messages user-safe. Notification actions may outlive the originating widget: avoid retaining disposed `State`/`BuildContext` or a closed tab's controller; check lifetime or use an application-owned action as appropriate.

## Split workspace panes

Call `view.workspace.requestPanes(...)` with zero, one, or two `ShellWorkspacePane(id:, title:, builder:, minWidth:)` entries for a total of up to three panes including the primary page. Secondary pane IDs must be nonempty/unique and minimum widths finite and at least 120 logical pixels.

Use `openSplit()`/`closeSplit()` to change visibility without discarding registrations. Optional positive weights include the primary pane and must match the total pane count. `setWeights(..., persist: false)` can update a drag; `persistLayout()` records its final layout. The shell renderer already owns normal resize handling and persists tab layout.

Request panes when their definitions actually change, not on every rebuild. Preserve restored visibility/weights instead of supplying default weights repeatedly. `selectCollapsedPane(id)` selects content when available width collapses the split. Let `ShellSplitView` handle available width and minimum sizes rather than adding a separate feature breakpoint system for the same panes.

Registration `splitPaneBuilder` and `ShellConfig.splitPaneBuilder` supply fallback secondary content; use tab-scoped requests for dynamic per-page panes. Each builder must create a fresh widget tree; share data or controllers only when their lifetime permits it, never the same `GlobalKey` or widget state across pane instances.
