# Repository Guidelines

## Project Structure

Targets are Android, iOS, macOS, Windows, Linux, and web. `lib/core/` holds shared code; `lib/pages/page1` through `page6` are feature placeholders; `lib/widgets/` and `lib/utils/` hold reusable UI. ARBs are in `assets/l10n/`, generated localizations in `lib/l10n/`, tests in `test/`, and platform files in matching top-level directories.

## Toolchain and Commands

`.fvmrc` pins Flutter 3.47.2. Prefix all Flutter and Dart commands with `fvm`:

- `fvm flutter pub get` — resolve dependencies after changing `pubspec.yaml`.
- `fvm dart format --line-length=120 lib test` — format Dart source and tests.
- `fvm flutter gen-l10n` — regenerate localization code after editing ARB files.
- `fvm flutter analyze` — run configured Dart and Flutter analysis.
- `fvm flutter test` — run unit and widget tests; use `fvm flutter test test/page1_usecases_test.dart` for one file.
- `fvm flutter run -d chrome` — launch the app in a browser.
- `fvm flutter build web` / `fvm flutter build apk` — build web or Android release output. Desktop targets use `fvm flutter build linux`, `fvm flutter build macos`, or `fvm flutter build windows` on a supported host.

## Architecture and Feature Changes

Flow is Page → UseCase → Repository → DataSource. Current `pageN_*` names are placeholders: replace `pageN` with the feature's snake_case name (for example, `garden_page.dart`). Follow the feature file pattern: `<feature>_page.dart`, `<feature>_datasource.dart`, `<feature>_repository.dart`, and `<feature>_usecases.dart`; use cases may be omitted for small features. Register dependencies in `lib/core/injection.dart`, expose use cases via `AppServices`, and update navigation in `lib/pages/home/page_navigator.dart`. Initialize GetIt before `runApp()`; UI reads services and settings through `AppScope.of(context)`. `SettingsController` persists JSON via `shared_preferences`.

## Style and Localization

Follow `analysis_options.yaml`: package imports, trailing commas, single quotes; avoid `print` (use `debugPrint`) and await futures or call `unawaited()`. Use two-space indentation, 120-column lines, `snake_case` files, `UpperCamelCase` types, and `lowerCamelCase` members. Add strings to the English/German ARBs in `assets/l10n/`, run `fvm flutter gen-l10n`, and access translations through `context.l10n`; do not edit generated files.

## Tests

Tests use `flutter_test`, end in `_test.dart`, and cover feature logic or widget behavior. GitHub Actions only publishes the wiki from `docs/wiki/` on relevant pushes to `skeleton`; it does not run app tests or builds.

## Commits and Pull Requests

Use Conventional Commit subjects, generally `feat(feature_name): ...` or `fix(feature_name): ...` (for example, `feat(garden): add garden overview`). Agents must never create pull requests; report the change and validation status to the user instead.
