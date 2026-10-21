---
name: flutter-template-shell
description: Integrate pages with this Flutter template's reusable shell or extend its desktop and mobile UI. Use for destination and tab registration, tab lifecycle, hierarchical navigation, right sidebar, status items, toolbar actions, commands, and split panes through the implemented public interfaces.
---

# Integrate with the reusable shell

Use the shell's registration and controller contracts for application content. Keep domain operations in feature use cases; see [flutter-template-feature](../flutter-template-feature/SKILL.md) when adding feature logic or dependency wiring.

Paths below are relative to the consuming repository root. Read its `AGENTS.md` and the current implementation of the contracts you use. The public API lives in `lib/pages/home/page_navigator.dart`; application examples live in `default_shell_config.dart`. `test/support/public_shell_feature.dart` and `test/shell_public_extension_test.dart` demonstrate integration from outside the shell. Prefer canonical `rightSidebar` names over their compatibility `inspector` aliases.

## Register destinations and views separately

A `ShellDestination` is a sidebar/mobile navigation section with its own workspace. A `ShellViewRegistration` describes content that can have multiple tab instances in a workspace. A page's internal hierarchy is a third concept, expressed with `ShellNavigationNode`.

Compose a `ShellConfig` and pass it to `HomePage(config: ..., mainNavigatorKey: ...)`. Extend the application's existing configuration with `copyWith` when retaining its registrations; construct a fresh configuration when replacing the example content. Do not keep numbered demo features as architectural dependencies or add feature imports to `page_navigator.dart`.

This neutral registration helper accepts the consuming feature's localized title and view builder:

```dart
ShellConfig registerFeature(
  ShellConfig config, {
  required String Function(BuildContext) title,
  required ShellViewBuilder buildView,
}) => config.copyWith(
  destinations: [
    ...config.destinations,
    ShellDestination(
      id: 'feature',
      title: title,
      icon: Icons.extension_outlined,
      defaultViewId: 'feature.workspace',
      allowedViewIds: const {'feature.workspace'},
    ),
  ],
  views: [
    ...config.views,
    ShellViewRegistration(
      id: 'feature.workspace',
      title: (context, _) => title(context),
      destinationId: 'feature',
      viewBuilder: buildView,
    ),
  ],
);
```

Choose application-specific stable IDs before shipping. Ensure IDs are unique within their registration collections, `defaultViewId` resolves, and `allowedViewIds` includes every view that should open in the section. A null allowlist allows every registered view; `destinationId` by itself is not an access restriction. Neither a destination allowlist nor a hidden item is authorization for application data.

Use `viewBuilder: (context, view) => ...` and pass its `ShellViewContext` to the feature page when needed. The older destination `builder`, view `builder`, and `isRoot` APIs are compatibility paths. A view's optional `routePath` participates in the existing shell route handling; do not add an independent router to open workspace tabs.

## Choose tab identity and reuse deliberately

| `ShellViewReusePolicy` | Behavior within the target workspace |
| --- | --- |
| `never` (default) | Opening creates an independent tab |
| `byRegistration` | Opening activates the existing tab for this registration |
| `byInstance` | Opening with the same explicit `instanceId` activates that instance; without one, creates a tab |

`view.tab.id` is the tab identity. `view.instanceId` identifies the resolved view instance. `view.parameters` carries JSON reconstruction data. Do not use a localized title or registration ID as the unique key for all page instances. Registering a shared service does not make its per-tab presentation state shared.

Reuse policies govern normal open requests. The shell's `+` action deliberately creates a new tab instance; preserve that explicit new-tab behavior when extending navigation.

Use `view.navigation.openView(registrationId, instanceId: ..., parameters: ...)`, `activateTab`, `closeTab`, and `selectSection` for shell navigation. Commands return futures; await them or explicitly use `unawaited` when their result is unnecessary. An open can return null if the target registration is unavailable or disallowed.

`openView` defaults to the owning tab's section. Pass `sectionId` explicitly for a different section; a registration's `destinationId` does not override this tab-scoped default. Let the shell manage tab creation, activation, close guards, persistence, and global open-tab search instead of manipulating its coordinator or settings from a page.

## Respect controller ownership and lifecycle

The shell owns `ShellViewContext` controllers and disposes them when the tab closes. Pages may subscribe to `view.lifecycle` (`restored`, `opened`, `activated`, `deactivated`, `closing`, `closed`) and must remove their listeners; they must not dispose the shell's controllers or share them between tabs.

The context wrapper can be rebuilt while its controllers remain stable. Compare the particular controller or tab identity when rewiring listeners. Inspect `view.lifecycle.value` and `view.isRestored` for initial state; a listener added after creation cannot observe earlier transitions. Pause view-only work on deactivation when appropriate; inactive tabs can remain mounted.

Publish contributions after the first frame, after dependencies change when necessary, or from user/state events. Avoid unconditional controller mutations in `build`: they notify shell listeners and can cause repeated rebuilds or reset a user's layout choices. Guard queued callbacks and asynchronous UI updates with `mounted`, and detach feature-owned subscriptions/resources on disposal.

Use `onCloseRequested` on `ShellViewRegistration` when a view needs a close decision. Keep unsaved state identifiable per tab; a registration-level guard receives the tab being closed, not just whichever tab happens to be active.

## Choose the extension point

Read [page-contributions.md](references/page-contributions.md) for the controller API relevant to the task: breadcrumbs, right sidebar, toolbar, status, notifications, or workspace panes. It also covers registration-level commands and content fallbacks. Load only the sections needed.

Read [design-and-validation.md](references/design-and-validation.md) when changing layout, input handling, accessibility, or shell behavior. Preserve the existing shell interaction model while integrating a feature; changing the reusable shell itself should address a demonstrated shared need.
