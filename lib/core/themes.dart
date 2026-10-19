import 'package:flutter/material.dart';

@immutable
class AppShellTokens extends ThemeExtension<AppShellTokens> {
  final Color canvas;
  final Color surface;
  final Color raised;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color focus;
  final double spacingScale;

  const AppShellTokens({
    required this.canvas,
    required this.surface,
    required this.raised,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.focus,
    required this.spacingScale,
  });

  @override
  AppShellTokens copyWith({
    Color? canvas,
    Color? surface,
    Color? raised,
    Color? border,
    Color? textPrimary,
    Color? textSecondary,
    Color? focus,
    double? spacingScale,
  }) {
    return AppShellTokens(
      canvas: canvas ?? this.canvas,
      surface: surface ?? this.surface,
      raised: raised ?? this.raised,
      border: border ?? this.border,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      focus: focus ?? this.focus,
      spacingScale: spacingScale ?? this.spacingScale,
    );
  }

  @override
  AppShellTokens lerp(covariant AppShellTokens? other, double t) {
    if (other == null) return this;
    return AppShellTokens(
      canvas: Color.lerp(canvas, other.canvas, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      raised: Color.lerp(raised, other.raised, t)!,
      border: Color.lerp(border, other.border, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      focus: Color.lerp(focus, other.focus, t)!,
      spacingScale: spacingScale + (other.spacingScale - spacingScale) * t,
    );
  }
}

class AppTheme {
  static const Map<String, Color> accents = {
    'steel': Color(0xFF789BB1),
    'blue': Color(0xFF397AA5),
    'green': Color(0xFF4F8A70),
    'violet': Color(0xFF7865A8),
  };

  static ThemeData light({String accentPreset = 'steel', bool comfortable = false}) =>
      _build(Brightness.light, accentPreset, comfortable);

  static ThemeData dark({String accentPreset = 'steel', bool comfortable = false}) =>
      _build(Brightness.dark, accentPreset, comfortable);

  static ThemeData _build(Brightness brightness, String accentPreset, bool comfortable) {
    final dark = brightness == Brightness.dark;
    final canvas = dark ? const Color(0xFF141A20) : const Color(0xFFF3F6F8);
    final surface = dark ? const Color(0xFF1D2630) : Colors.white;
    final raised = dark ? const Color(0xFF26313D) : const Color(0xFFECF1F5);
    final secondaryText = dark ? const Color(0xFFA9B6BF) : const Color(0xFF556976);
    final scheme = ColorScheme.fromSeed(
      seedColor: accents[accentPreset] ?? accents['steel']!,
      brightness: brightness,
      surface: surface,
      error: const Color(0xFFB3261E),
    );
    final tokens = AppShellTokens(
      canvas: canvas,
      surface: surface,
      raised: raised,
      border: dark ? const Color(0xFF34414C) : const Color(0xFFD4DDE4),
      textPrimary: dark ? const Color(0xFFECF1F5) : const Color(0xFF1B2B37),
      textSecondary: secondaryText,
      focus: scheme.primary,
      spacingScale: comfortable ? 1.15 : 1,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: canvas,
      canvasColor: surface,
      cardColor: surface,
      visualDensity: comfortable ? VisualDensity.comfortable : VisualDensity.standard,
      extensions: [tokens],
      dividerColor: tokens.border,
      focusColor: tokens.focus.withValues(alpha: 0.16),
      textTheme: TextTheme(
        displayMedium: TextStyle(fontSize: 30, fontWeight: FontWeight.w600, color: tokens.textPrimary),
        displaySmall: TextStyle(fontSize: 26, fontWeight: FontWeight.w600, color: tokens.textPrimary),
        headlineSmall: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: tokens.textPrimary),
        bodyMedium: TextStyle(color: secondaryText, fontWeight: FontWeight.w500, letterSpacing: 0.2),
        labelSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: secondaryText),
        labelMedium: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: tokens.textPrimary),
        labelLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: tokens.textPrimary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: const OutlineInputBorder(),
        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: tokens.focus, width: 2)),
      ),
    );
  }
}
