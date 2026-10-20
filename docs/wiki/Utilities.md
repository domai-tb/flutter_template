# Localization (l10n)

The template uses Flutter's built-in `gen-l10n` system with `.arb` files.

## Where Translations Live

- `assets/l10n/l10n_en.arb`
- `assets/l10n/l10n_de.arb`

Configuration:

- `l10n.yaml`

Generated output:

- `lib/l10n/l10n.dart`
- `lib/l10n/l10n_en.dart`
- `lib/l10n/l10n_de.dart`

## Using Translations In Widgets

Use the `BuildContext` extension:

- `lib/l10n/l10n_x.dart`

Example:

```dart
Text(context.l10n.page1Title)
```

## Adding A New String

1. Add the key to all supported locales in `assets/l10n/`.
2. Re-run localization generation with `fvm flutter gen-l10n`.
3. Use the new key via `context.l10n.<key>`.


---

# Shared Widgets

Cross-feature widgets live in:

- `lib/widgets/`

The goal is to keep page modules small and avoid duplicating UI components across features.

App-shell components live separately in `lib/pages/home/widgets/`. That folder contains destination navigation, the tab strip, status and notification UI, breadcrumb menus, and right-sidebar sections. Shell pages should use the controllers in `ShellViewContext` instead of importing those shell widgets directly.

## Included Examples

- Buttons: `app_button.dart`
- Icon button: `app_icon_button.dart`
- Search bar: `app_search_bar.dart`
- Segmented control: `app_segmented_triple_control.dart`
- Scroll-to-top FAB: `scroll_to_top_button.dart`

If a widget is only used by a single feature, keep it inside that feature folder instead.


---

# Settings (Persistent)

`SettingsController` in `lib/core/settings.dart` loads settings at startup and writes updates to SharedPreferences as JSON under `app_settings_json_v1`.

The current schema is version 6. It stores:

- Theme mode, accent, density, text scaling, locale, and onboarding completion.
- Navigation item order and visibility.
- Open tabs, selected destinations, contexts, and modules.
- Right-sidebar visibility and width, plus split-pane visibility and pane ratios.

The right-sidebar width preference is currently serialized under the historical `inspectorWidth` key. Treat the settings model as the persistence contract: add defaults when adding fields and preserve compatibility with saved JSON. See [Architecture](Architecture.md) for the shell and settings overview.

---

# Architecture

See the main [Architecture guide](Architecture.md) for the feature folder layout, layer boundaries, dependency injection, shell extension points, and settings persistence.

## App shell

`lib/pages/home/` provides the adaptive app shell and its public extension APIs. `ShellConfig` registers destinations, workspace views, modules, commands, status providers, a right sidebar, and optional split-pane content. Each view receives a `ShellViewContext` with tab-scoped breadcrumb, navigation, right-sidebar, status, toolbar, and workspace controllers. See the [Architecture](Architecture.md) page for the behavior and extension points.

---

