import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Esta classe vai gerir o estado do tema (claro/escuro)
class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  bool _isInitialized = false;

  ThemeMode get themeMode => _themeMode;

  ThemeProvider() {
    _loadThemeFromPrefs();
  }

  // Carrega a preferência de tema guardada no dispositivo
  Future<void> _loadThemeFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final isDarkMode = prefs.getBool('isDarkMode') ?? false;
    _themeMode = isDarkMode ? ThemeMode.dark : ThemeMode.light;
    _isInitialized = true;
    notifyListeners(); // Notifica os widgets para reconstruir com o tema correto
  }

  // Alterna o tema e guarda a preferência
  void toggleTheme(bool isDarkMode) async {
    _themeMode = isDarkMode ? ThemeMode.dark : ThemeMode.light;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', isDarkMode);
    notifyListeners(); // Notifica a aplicação da mudança
  }
}
