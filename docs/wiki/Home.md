# Flutter Template

This repository is a Flutter app template for Android, iOS, macOS, Windows, Linux, and web. It includes an adaptive app shell and six example feature modules (`page1` through `page6`).

Feature modules keep their page, datasource, repository, and singular use-case files together. Optional entities and feature-only widgets live in `entities/` and `widgets/` subfolders. The shell APIs do not depend on the placeholder pages; the default example registrations live in `lib/pages/home/default_shell_config.dart`.

## Structure
- `lib/pages/page1` ... `lib/pages/page6`: flat feature modules with optional `entities/` and `widgets/` folders
- `lib/core`: app-wide concerns (settings, theme, DI)
- `lib/pages/home`: shell implementation and extension contracts
- `lib/widgets`: reusable UI building blocks

## Replace Placeholders
1. Pick a page folder (e.g. `lib/pages/page1`).
2. Replace the datasource, repository, use case, entities, and page with your implementation.
3. Register feature dependencies in `lib/core/injection.dart` and expose use cases through `AppServices`.
4. Keep shell registrations in `default_shell_config.dart` or pass a `ShellConfig` from the host app.

## License
See `LICENSE`.
