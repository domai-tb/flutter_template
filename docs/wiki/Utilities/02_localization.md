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

