# Getting Started

## Toolchain

This checkout pins Flutter 3.47.2 in `.fvmrc`. Install FVM and the prerequisites for your host platform, then run:

```sh
fvm install
fvm flutter pub get
fvm flutter devices
```

## Run the app

```sh
fvm flutter run -d linux
fvm flutter run -d chrome
fvm flutter run
```

The first command runs the Linux desktop app, the second runs Flutter Web in Chrome, and the third selects an available device. Android requires Android SDK tooling; iOS and macOS builds require macOS and Xcode; Windows builds require Windows desktop tooling.

The shell uses bottom destination navigation on phones and side navigation with tabs on wider layouts. A destination activity panel can appear at widths of 800 px and above. At 1200 px and above the right sidebar can dock beside the workspace; on narrower layouts it opens as a drawer. These are responsive layout thresholds, not device restrictions.

## Verify changes

```sh
fvm dart format --line-length=120 lib test
fvm flutter gen-l10n
fvm flutter analyze
fvm flutter test test/shell_test.dart test/shell_workspace_test.dart test/shell_public_extension_test.dart test/shell_auth_navigation_test.dart
```

Run `fvm flutter gen-l10n` after changing an ARB file in `assets/l10n/`. During the UI redesign, golden image generation and comparison are not required verification. Use focused functional tests for navigation, tabs, persistence, shortcuts, notifications, and pointer behavior. Capture runtime screenshots at the viewport sizes in the UI/UX specification for visual inspection; they are diagnostic images, not golden baselines.

## Extend the shell

Pass a `ShellConfig` to `HomePage`. Register stable navigation entries with `ShellDestination` and tab content with `ShellViewRegistration`. `ShellViewContext` exposes page-level controllers for hierarchical breadcrumbs, tab navigation, right-sidebar sections, status items, toolbar actions, and split panes. Page 1 demonstrates the breadcrumb and sidebar APIs. See [Architecture](Architecture.md), [Pages](Pages.md), and the root [README](../../README.md) for more detail.

Keep IDs stable when labels change so saved destination, tab, and breadcrumb state can be restored. Add a `settings` destination to a custom configuration if it should provide the built-in Settings action.
