# Architecture

This repository is a Flutter app template that demonstrates a lightweight, layered structure you can copy for new features.

## Folder Layout

- `lib/core/`
  - Cross-cutting concerns (app scope, settings, themes, etc.).
- `lib/core/injection.dart`
  - Dependency injection wiring (GetIt).
- `lib/l10n/`
  - Generated localization code (see the Localization page).
- `lib/pages/`
  - Feature modules. In this skeleton they are `page1` to `page6`.
  - Each module demonstrates a layered approach:
    - `*_datasource.dart` for I/O (API, DB, etc.)
    - `*_repository.dart` for domain-friendly access
    - `*_usecases.dart` for orchestration / business rules
    - `*_entity.dart` for immutable data models
    - `*_page.dart` for UI
- `lib/widgets/`
  - Shared widgets used across multiple pages (buttons, search bar, etc.).

## Dependency Wiring

The skeleton uses GetIt for dependency injection, wired in one place:

- `lib/core/injection.dart` registers datasources, repositories, and usecases, and builds `AppServices`.
- `lib/main.dart` calls `init()` at startup.
- `lib/core/app_scope.dart` exposes `SettingsController` and `AppServices` to the widget tree (so pages stay free of plugin imports).

Pages access services via:

- `AppScope.of(context).services.pageN`

For the full architecture description, see [Architecture](Architecture).

---

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
2. Re-run localization generation (for example `flutter gen-l10n` or `flutter run` which triggers generation).
3. Use the new key via `context.l10n.<key>`.


---

# Settings (Persistent)

The template keeps UI state in memory but persists user settings to local storage.

## Where It Lives

- `lib/core/settings.dart`

`SettingsController` loads its initial state once at startup and persists updates via `shared_preferences`.

## What Is Stored

The `Settings` model is serialized to JSON and includes (at minimum):

- Theme mode flags
- Text scaling preference
- Onboarding completion flag (`didCompleteOnboarding`)
- Selected language (`localeCode`) or `null` for system language

## Why JSON

JSON keeps the migration story simple for a template:

- Add a new field with a default in `Settings.fromJson(...)`
- Old installs continue to load


---

# Shared Widgets

Shared widgets live in:

- `lib/widgets/`

The goal is to keep page modules small and avoid duplicating UI components across features.

## Included Examples

- Buttons: `app_button.dart`
- Icon button: `app_icon_button.dart`
- Search bar: `app_search_bar.dart`
- Segmented control: `app_segmented_triple_control.dart`
- Scroll-to-top FAB: `scroll_to_top_button.dart`

If a widget is only used by a single feature, keep it inside that feature folder instead.


---

