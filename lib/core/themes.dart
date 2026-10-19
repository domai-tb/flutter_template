import 'package:flutter/material.dart';

/// App theme definitions (no custom fonts, Material 3).
class AppTheme {
  static final ThemeData light = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: Colors.black,
      secondary: Color.fromRGBO(21, 0, 62, 1),
      surface: Colors.white,
      onSurface: Colors.black,
      error: Colors.red,
    ),
    cardColor: Colors.white,
    textTheme: const TextTheme(
      displayMedium: TextStyle(
        fontSize: 30,
        fontWeight: FontWeight.w600,
      ),
      displaySmall: TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.w600,
      ),
      headlineSmall: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w700,
      ),
      bodyMedium: TextStyle(
        color: Color.fromARGB(255, 129, 129, 129),
        fontWeight: FontWeight.w500,
        letterSpacing: 0.2,
      ),
      labelSmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      labelMedium: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
      ),
      labelLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  static final ThemeData dark = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: Colors.white,
      secondary: Color.fromRGBO(49, 113, 236, 1),
      surface: Color.fromRGBO(14, 20, 32, 1),
      onSurface: Colors.white,
      error: Colors.red,
    ),
    cardColor: const Color.fromRGBO(17, 25, 38, 1),
    textTheme: const TextTheme(
      displayMedium: TextStyle(
        fontSize: 30,
        fontWeight: FontWeight.w600,
      ),
      displaySmall: TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.w600,
      ),
      headlineSmall: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w700,
      ),
      bodyMedium: TextStyle(
        color: Color.fromRGBO(184, 186, 191, 1),
        fontWeight: FontWeight.w500,
        letterSpacing: 0.2,
      ),
      labelSmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      labelMedium: TextStyle(
        color: Color.fromRGBO(184, 186, 191, 1),
        fontSize: 15,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
      ),
      labelLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}
