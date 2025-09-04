import 'package:flutter/material.dart';
import 'screens/landing_screen.dart'; // Importa a nossa tela de um novo arquivo

// A função main() continua sendo o ponto de entrada.
void main() {
  runApp(const EcoEnergiaApp());
}

// O widget principal agora está bem mais limpo.
// Ele apenas configura o tema e aponta para a tela inicial.
class EcoEnergiaApp extends StatelessWidget {
  const EcoEnergiaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'EcoEnergia',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        fontFamily: 'Inter',
      ),
      // A tela inicial continua sendo a LandingScreen.
      home: const LandingScreen(),
    );
  }
}
