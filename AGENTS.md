# Repository Guidelines

## Project Structure

Targets are Android, iOS, macOS, Windows, Linux, and web. `lib/core/` holds shared services and app configuration; `lib/pages/home/` holds the shell; `lib/pages/page1` through `page6` are feature placeholders; `lib/widgets/` holds reusable UI. ARBs are in `assets/l10n/`, generated localizations in `lib/l10n/`, tests in `test/`, and platform files in matching top-level directories.

## Agent Skills

Before implementing or reviewing changes, read the applicable skill's `SKILL.md` and follow its workflow:

- [flutter-template-feature](.agents/skills/flutter-template-feature/SKILL.md): Use when adding or refactoring features, choosing layer ownership, wiring dependencies, or integrating settings, authentication, and persistence. Applies to every feature, including Settings and Profile.
- [flutter-template-shell](.agents/skills/flutter-template-shell/SKILL.md): Use when registering destinations or tab views, publishing page contributions through `ShellViewContext`, or changing shell layout and interactions. Covers tab lifecycle, hierarchical navigation, right sidebar, toolbar, commands, status, notifications, split panes, and responsive design.
- [flutter-version-manager](.agents/skills/flutter-version-manager/SKILL.md): Use when configuring or troubleshooting the pinned Flutter/Dart SDK, FVM setup, or SDK consistency across development and CI.

For a feature exposed through the shell, read the feature skill first, then the shell skill. For changes confined to one area, use the corresponding skill. Load linked references only for the interfaces or services the task touches, and check their current source before implementing against them.

These workflows apply to applications derived from this template regardless of business domain. Replace example page content with the application's own behavior while preserving the architecture and public shell contracts. When intentionally changing a shared contract, update the affected skill guidance and references alongside it.

## Toolchain and Commands

`.fvmrc` pins Flutter 3.47.2. Prefix all Flutter and Dart commands with `fvm`:

- `fvm flutter pub get` — resolve dependencies after changing `pubspec.yaml`.
- `fvm dart format --line-length=120 lib test` — format Dart source and tests.
- `fvm flutter gen-l10n` — regenerate localization code after editing ARB files.
- `fvm flutter analyze` — run configured Dart and Flutter analysis.
- `fvm flutter test` — run unit and widget tests; use `fvm flutter test test/page1_usecase_test.dart` for one file.
- `fvm flutter run -d chrome` — launch the app in a browser.
- `fvm flutter build web` / `fvm flutter build apk` — build web or Android release output. Desktop targets use `fvm flutter build linux`, `fvm flutter build macos`, or `fvm flutter build windows` on a supported host.

## Architecture and Feature Changes

Pages call use cases, which call repositories and datasources. Datasources and repositories belong to the Data layer, use cases and entities to the Domain layer, and pages plus presentation controllers to the Presentation layer. Keep feature files flat: `<feature>_page.dart`, `<feature>_datasource.dart`, `<feature>_repository.dart`, and singular `<feature>_usecase.dart`. Add `entities/` or `widgets/` only when useful; keep single-file layers in the feature root and create layer-specific folders only when they contain multiple related files. Replace `pageN` with the feature's snake_case name (for example, `garden_page.dart`). Treat 500 lines as a review guideline: extract cohesive responsibilities as files grow, not just to satisfy a count.

Register dependencies in `lib/core/injection.dart`, expose feature use cases via `AppServices`, and initialize GetIt before `runApp()`. The shell contracts in `lib/pages/home/page_navigator.dart` do not import placeholder pages; default example registrations live in `default_shell_config.dart`. UI reads services and settings through `AppScope.of(context)`. `SettingsController` persists JSON via `shared_preferences`.

## Style and Localization

Follow `analysis_options.yaml`: package imports, trailing commas, single quotes; avoid `print` (use `debugPrint`) and await futures or call `unawaited()`. Use two-space indentation, 120-column lines, `snake_case` files, `UpperCamelCase` types, and `lowerCamelCase` members. Add strings to the English/German ARBs in `assets/l10n/`, run `fvm flutter gen-l10n`, and access translations through `context.l10n`; do not edit generated files.

## Tests

Tests use `flutter_test`, end in `_test.dart`, and cover feature logic or widget behavior. `.github/workflows/flutter.yml` resolves dependencies with the version in `.fvmrc`, checks formatting and analysis, and runs unit/widget tests. `.github/workflows/docs.yml` publishes the wiki from `docs/wiki/` on relevant pushes to `skeleton`.

## Commits and Pull Requests

Use Conventional Commit subjects, generally `feat(feature_name): ...` or `fix(feature_name): ...` (for example, `feat(garden): add garden overview`). Agents must never create pull requests; report the change and validation status to the user instead.
