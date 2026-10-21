# Contributing

Contributions and thoughtful feedback are welcome. For substantial changes, open an issue first to discuss the approach.

## Development environment setup

Install Git and [Flutter Version Management (FVM)](https://fvm.app/), then from the repository root run:

```sh
fvm install
fvm flutter pub get
```

Install any platform-specific Flutter prerequisites for the target you plan to run.

## Local development workflow

Create a branch, make a focused change, and run the checks below before opening a pull request. After editing localization ARB files, regenerate them with `fvm flutter gen-l10n`.

For platform prerequisites, follow Flutter's official guides for [Android](https://docs.flutter.dev/platform-integration/android/setup), [iOS](https://docs.flutter.dev/platform-integration/ios/setup), and [desktop](https://docs.flutter.dev/platform-integration/desktop), including its [Windows](https://docs.flutter.dev/platform-integration/windows/setup), [macOS](https://docs.flutter.dev/platform-integration/macos/setup), and [Linux](https://docs.flutter.dev/platform-integration/linux/setup) setup guides.

- Web: `fvm flutter run -d chrome`
- Mobile: start an emulator or simulator, or connect a device, then run `fvm flutter run` and select a target.
- Desktop: run `fvm flutter run -d windows`, `fvm flutter run -d macos`, or `fvm flutter run -d linux` on a host configured for that platform.

## Coding standards

Follow the existing Dart style and `analysis_options.yaml`: two-space indentation, package imports, trailing commas, and no `print`. Keep features in the existing layers and use `context.l10n` for user-facing strings; edit ARB files rather than generated localization files.

## Testing requirements

Before submitting, format and run analysis and tests:

```sh
fvm dart format --line-length=120 lib test
fvm flutter analyze
fvm flutter test
```

Add or update tests for behavior changes. Mention any checks you could not run in the pull request.

## Branch naming conventions

Use a short lowercase name with a type prefix: `feat/`, `fix/`, `docs/`, or `chore/` (for example, `fix/settings-load`).

## Commit message conventions

Use [Conventional Commits](https://www.conventionalcommits.org/), such as `feat(settings): add theme selection` or `fix(home): preserve selected tab`.

## Pull request process

Open a pull request against the repository's default branch. Describe the problem and change, link related issues, list validation performed, and include screenshots for visible UI changes. Keep the pull request focused and update it in response to review feedback.

## Code review process

Maintainers review contributions for correctness, fit with the project, and adequate tests and documentation. Reviewers may request changes or clarification; discuss feedback respectfully. Maintainers decide when a contribution is ready to merge.
