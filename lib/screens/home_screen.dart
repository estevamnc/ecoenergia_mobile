import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import 'history_screen.dart';
import 'simulator_screen.dart';
import 'tips_screen.dart';
import 'settings_screen.dart';

// Esta tela será o container principal do app após o login.
// É um StatefulWidget porque precisa "lembrar" qual aba está selecionada.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Guarda o índice da aba atualmente selecionada. Começa em 0 (Dashboard).
  int _selectedIndex = 0;

  // Lista de todas as telas que a nossa barra de navegação pode mostrar.
  static final List<Widget> _widgetOptions = <Widget>[
    const DashboardScreen(),
    const HistoryScreen(),
    const SimulatorScreen(),
    const TipsScreen(),
    const SettingsScreen(),
  ];

  // Função chamada quando o usuário toca em uma das abas.
  void _onItemTapped(int index) {
    // setState notifica o Flutter que o estado mudou e a tela precisa ser redesenhada.
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // O corpo da tela exibe o widget da lista que corresponde ao índice selecionado.
      body: Center(child: _widgetOptions.elementAt(_selectedIndex)),
      // A barra de navegação inferior.
      bottomNavigationBar: BottomNavigationBar(
        // Os ícones e textos para cada aba.
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view_outlined),
            activeIcon: Icon(Icons.grid_view_rounded),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            activeIcon: Icon(Icons.bar_chart_rounded),
            label: 'Histórico',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calculate_outlined),
            activeIcon: Icon(Icons.calculate_rounded),
            label: 'Simulador',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.lightbulb_outline),
            activeIcon: Icon(Icons.lightbulb_rounded),
            label: 'Dicas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings_rounded),
            label: 'Ajustes',
          ),
        ],
        currentIndex: _selectedIndex, // A aba que está atualmente ativa.
        selectedItemColor: const Color(0xFF3B82F6), // Cor do ícone ativo
        unselectedItemColor: Colors.grey, // Cor dos ícones inativos
        showUnselectedLabels: true, // Mostra o texto das abas inativas
        onTap: _onItemTapped, // A função a ser chamada ao tocar.
        type:
            BottomNavigationBarType.fixed, // Garante que todas as abas apareçam
      ),
    );
  }
}
