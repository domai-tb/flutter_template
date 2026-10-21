---
name: flutter-template-feature
description: Add or refactor features in this Flutter template or an application derived from it. Use for feature ownership, layered architecture, dependency injection, settings, and authentication integration. Pair with flutter-template-shell when exposing a feature through the shell.
---

# Build features in the template

Use this workflow for any application domain. The numbered pages are replaceable examples; their data and behavior are not requirements for consuming applications.

All source paths below are relative to the consuming repository root. Read its `AGENTS.md`, `pubspec.yaml`, and `.fvmrc` first; follow its current instructions and package name. Inspect the relevant implementation before changing it. If a referenced file has moved, locate the corresponding contract rather than recreating the old structure.

## Choose the owner and trace the change

Identify the feature that owns the state and operation. Trace its page/controller → use case → repository → datasource, including callers, dependency registration, and affected tests. Extend that path instead of creating a parallel service or fetching data directly in a widget.

| Responsibility | Location and boundary |
| --- | --- |
| Pages, feature widgets, presentation controllers | `lib/pages/<feature>/`; render state and dispatch actions through use cases |
| Use cases and entities | Same feature; express operations and models independently of shell layout |
| Repositories | Same feature, Data layer; map datasource results and coordinate data access |
| Datasources | Same feature, Data layer; own API, database, filesystem, and platform access |
| App composition and shared infrastructure | `lib/core/`; dependency wiring, scope, themes, and shared shell services |
| Widgets reused by unrelated features | `lib/widgets/`; feature-only widgets stay with their feature |

Settings and Profile follow the same feature architecture under `lib/pages/settings/` and `lib/pages/profile/`. A feature remains a feature even when the shell displays it as a utility. Do not move its entities, storage, or use cases into `core/` just because several pages use it.

## Implement the smallest complete feature

Keep small features flat:

```text
lib/pages/<feature>/
  <feature>_page.dart
  <feature>_usecase.dart
  <feature>_repository.dart
  <feature>_datasource.dart
```

Use a singular `_usecase.dart` filename. Add an entity file or `entities/` and `widgets/` when useful. Introduce layer directories only when several related files justify them; do not create empty layers for presentation-only behavior. Around 500 lines is a prompt to extract a cohesive responsibility, not an enforced file limit.

Keep new domain rules independent of `BuildContext`, shell controllers, and platform plugins. Translate external data and failures at the Data boundary. Let presentation decide how to show loading, empty, error, and retry states. Reuse existing failure/result conventions rather than introducing a second framework.

Separate shared data from per-view state. Repositories or services can be shared; a tab's selection, search text, drafts, focus nodes, scroll controllers, and navigation state belong to that tab's widget or presentation controller. Scope dependencies with that ownership in mind; registering a mutable editor controller as a singleton makes tabs interfere with each other.

## Wire dependencies through the composition root

1. Register datasource → repository → use case in `lib/core/injection.dart`, using constructor injection between layers. Await required initialization before `runApp()` as `lib/main.dart` does.
2. Expose the use case through `AppServices` in `lib/core/app_services.dart` and include it in the aggregate's GetIt registration. Update other `AppServices` construction sites, including test fixtures, when its constructor changes.
3. Access dependencies in UI through `AppScope.of(context).services`, or pass the use case from a parent. Do not add GetIt lookups or plugin imports to feature widgets.
4. Obtain inherited dependencies in `didChangeDependencies` or `build`, not `initState`. Initialize asynchronous loading once per dependency/identity change; do not restart it on every rebuild.
5. Observe mutable controllers explicitly with their listenable API. `AppScope` exposes stable controller objects; it does not rebuild dependents on every internal settings or service update. Remove listeners and dispose only resources owned by the feature.

When exposing the feature as a destination or tab, use [flutter-template-shell](../flutter-template-shell/SKILL.md). Keep registrations in application composition (the default example is `default_shell_config.dart`), and keep the generic shell contract free of feature imports.

For changes to settings storage, session integration, or persistence compatibility, read [platform-services.md](references/platform-services.md).

## Keep presentation consistent

Use `Theme.of(context)`, the existing shared widgets, and `AppShellTokens`/`AppShellMetrics` from `lib/core/themes.dart`. Add user-facing strings to the application's ARBs under `assets/l10n/`, regenerate with `fvm flutter gen-l10n`, and access them through `context.l10n`. Do not hand-edit `lib/l10n/`.

Read the shell skill's [design and validation guidance](../flutter-template-shell/references/design-and-validation.md) when changing layout or interactions. It covers desktop density, touch behavior, accessibility, and geometry checks without prescribing application content.

## Finish the integration

Use FVM for Flutter/Dart commands and apply the command wrappers required by the repository. Format changed Dart files with `fvm dart format --line-length=120`, run `fvm flutter analyze`, and run the relevant existing tests. Add focused regression coverage for substantive logic or interaction changes; prioritize observable behavior over implementation details.

Check that the feature loads through its registered use case, handles failures, and retains independent state across two instances if multiple tabs are supported. For persisted changes, verify restoration and compatibility with existing data. Keep test and golden policies in the consuming repository's current instructions; do not change those policies as a side effect of adding a feature.

Report the integration points changed, verification performed, and any remaining limitations. Follow the repository's commit and delivery rules when those actions are requested.
