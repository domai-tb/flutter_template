# Settings (Persistent)

`SettingsController` in `lib/core/settings.dart` loads settings at startup and writes updates to SharedPreferences as JSON under `app_settings_json_v1`.

The current schema is version 6. It stores:

- Theme mode, accent, density, text scaling, locale, and onboarding completion.
- Navigation item order and visibility.
- Open tabs, selected destinations, contexts, and modules.
- Right-sidebar visibility and width, plus split-pane visibility and ratio.

The right-sidebar width preference is currently serialized under the historical `inspectorWidth` key. Treat the settings model as the persistence contract: add defaults when adding fields and preserve compatibility with saved JSON. See [Architecture](../Architecture.md) for the shell and settings overview.
