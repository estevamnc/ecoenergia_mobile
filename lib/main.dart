import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/theme_provider.dart';
import 'screens/landing_screen.dart';
import 'theme/app_theme.dart';
import 'services/auth_service.dart'; // Importa o AuthService

void main() {
  // Envolve a aplicação com os nossos providers
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        Provider(create: (_) => AuthService()),
      ],
      child: const EcoEnergiaApp(),
    ),
  );
}

class EcoEnergiaApp extends StatelessWidget {
  const EcoEnergiaApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Escuta as mudanças no ThemeProvider
    final themeProvider = Provider.of<ThemeProvider>(context);

    // O MaterialApp agora usa os temas que definimos
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'EcoEnergia',
      // Define o tema claro a ser usado
      theme: AppTheme.lightTheme,
      // Define o tema escuro a ser usado
      darkTheme: AppTheme.darkTheme,
      // Controla qual tema está ativo com base no nosso provider
      themeMode: themeProvider.themeMode,
      home: const LandingScreen(),
    );
  }
}
