import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/panel_asistente.dart';
import 'ayuda_screen.dart';
import 'inicio_screen.dart';
import 'perfil_screen.dart';
import 'produccion_screen.dart';
import 'rutas_screen.dart';

/// Caparazón principal de la app: navegación inferior por pestañas (el
/// patrón más reconocible mundialmente en apps móviles — Instagram,
/// WhatsApp, la mayoría de apps bancarias) + un botón flotante de
/// micrófono siempre visible para hablar con el asistente sin importar
/// en qué pantalla esté el usuario.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _indice = 0;

  static const _titulos = ['Inicio', 'Perfil de empresa', 'Producción', 'Rutas', 'Ayuda'];

  final List<Widget> _pantallas = [
    const InicioScreen(),
    const PerfilScreen(),
    const ProduccionScreen(),
    const RutasScreen(),
    const AyudaScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, estado, _) {
        if (estado.pestanaSolicitada != null && estado.pestanaSolicitada != _indice) {
          final destino = estado.pestanaSolicitada!;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            setState(() => _indice = destino);
            estado.confirmarNavegacionConsumida();
          });
        } else if (estado.pestanaSolicitada != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) => estado.confirmarNavegacionConsumida());
        }

        if (estado.cargando) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        return Scaffold(
          appBar: AppBar(title: Text(_titulos[_indice])),
          body: IndexedStack(index: _indice, children: _pantallas),
          floatingActionButton: FloatingActionButton(
            backgroundColor: AppTheme.verdeAccion,
            onPressed: () => abrirPanelAsistente(context),
            tooltip: 'Hablar con el asistente',
            child: const Icon(Icons.mic, color: Colors.white),
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _indice,
            onTap: (i) => setState(() => _indice = i),
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Inicio'),
              BottomNavigationBarItem(icon: Icon(Icons.store_outlined), label: 'Perfil'),
              BottomNavigationBarItem(icon: Icon(Icons.checkroom_outlined), label: 'Producción'),
              BottomNavigationBarItem(icon: Icon(Icons.local_shipping_outlined), label: 'Rutas'),
              BottomNavigationBarItem(icon: Icon(Icons.help_outline), label: 'Ayuda'),
            ],
          ),
        );
      },
    );
  }
}
