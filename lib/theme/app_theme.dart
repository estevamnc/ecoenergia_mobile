import 'package:flutter/material.dart';

class AppTheme {
  // Cores partilhadas
  static const primaryColor = Color(0xFF3B82F6);
  static const dangerColor = Color(0xFFEF4444);
  static const successColor = Color(0xFF22C55E);

  // Tema Claro
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: primaryColor,
    scaffoldBackgroundColor: const Color(0xFFF8F9FA),
    cardColor: Colors.white,
    dividerColor: const Color(0xFFDEE2E6),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Color(0xFF212529)),
      bodyMedium: TextStyle(color: Color(0xFF6C757D)),
      titleLarge: TextStyle(
        color: Color(0xFF212529),
        fontWeight: FontWeight.bold,
      ),
    ),
    colorScheme: const ColorScheme.light(
      primary: primaryColor,
      secondary: primaryColor,
      error: dangerColor,
      surface: Color(0xFFF8F9FA),
    ),
    // ... outras propriedades do tema claro
  );

  // Tema Escuro
  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: primaryColor,
    scaffoldBackgroundColor: const Color(0xFF121212),
    cardColor: const Color(0xFF1E1E1E),
    dividerColor: const Color(0xFF333333),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.white),
      bodyMedium: TextStyle(color: Color(0xFFb0b0b0)),
      titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
    ),
    colorScheme: const ColorScheme.dark(
      primary: primaryColor,
      secondary: primaryColor,
      error: dangerColor,
      surface: Color(0xFF121212),
    ),
    // ... outras propriedades do tema escuro
  );
}
