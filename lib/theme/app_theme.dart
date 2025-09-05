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
    // CORREÇÃO: Usar CardThemeData em vez de CardTheme
    cardTheme: const CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
        side: BorderSide(color: Color(0xFFDEE2E6)),
      ),
    ),
    colorScheme: const ColorScheme.light(
      primary: primaryColor,
      secondary: primaryColor,
      error: dangerColor,
      background: Color(0xFFF8F9FA),
    ),
  );

  // Tema Escuro ATUALIZADO
  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: primaryColor,
    scaffoldBackgroundColor: Colors.black, // Fundo preto profundo
    cardColor: const Color(
      0xFF1C1C1E,
    ), // Cinza escuro para os cards, como na referência
    dividerColor: const Color(0xFF333333),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.white),
      bodyMedium: TextStyle(color: Color(0xFFb0b0b0)),
      titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
    ),
    // CORREÇÃO: Usar CardThemeData em vez de CardTheme
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        side: BorderSide(color: const Color(0xFF1C1C1E).withOpacity(0.5)),
      ),
    ),
    colorScheme: const ColorScheme.dark(
      primary: primaryColor,
      secondary: primaryColor,
      error: dangerColor,
      background: Colors.black,
    ),
  );
}
