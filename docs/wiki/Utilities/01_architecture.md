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
