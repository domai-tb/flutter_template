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

