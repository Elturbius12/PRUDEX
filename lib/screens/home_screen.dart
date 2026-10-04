import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:asistente_pl/state/app_state.dart';
import 'package:asistente_pl/state/theme_state.dart';
import 'package:asistente_pl/theme/app_colors.dart';
import 'package:asistente_pl/screens/chat_screen.dart';
import 'package:asistente_pl/screens/modelo_screen.dart';
import 'package:asistente_pl/screens/resultados_screen.dart';
import 'package:asistente_pl/screens/config_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final screens = <Widget>[
      const ChatScreen(),
      const ModeloScreen(),
      const ResultadosScreen(),
      const ConfigScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: state.tabActual,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              width: 1,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: state.tabActual,
          onTap: state.setTab,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline),
              activeIcon: Icon(Icons.chat_bubble),
              label: 'Asistente',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.grid_view_outlined),
              activeIcon: Icon(Icons.grid_view),
              label: 'Modelo',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.insights_outlined),
              activeIcon: Icon(Icons.insights),
              label: 'Resultados',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings),
              label: 'Ajustes',
            ),
          ],
        ),
      ),
    );
  }
}
