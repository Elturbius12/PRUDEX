import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';

class InicioScreen extends StatelessWidget {
  const InicioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final estado = context.read<AppState>();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          '¿Qué hace este asistente?',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppTheme.azulOscuro),
        ),
        const SizedBox(height: 8),
        const Text(
          'Le hablas al sistema sobre un problema operativo real (qué producir o cómo '
          'repartir tu mercadería) y él arma el modelo matemático de Programación Lineal, '
          'lo resuelve con un motor Simplex propio, y te explica el resultado en dos '
          'niveles: uno simple para decidir, y uno técnico con el detalle matemático.',
          style: TextStyle(fontSize: 13.5, height: 1.4),
        ),
        const SizedBox(height: 18),
        _TarjetaAsistente(
          emoji: '🧵',
          titulo: 'Asistente de producción',
          descripcion:
              '¿Cuánto producir de cada producto (chompas, chalinas, ponchos…) para '
              'maximizar utilidad, dado tu hilo y tiempo disponibles?',
          onTap: () => estado.pedirNavegacion(2),
        ),
        const SizedBox(height: 10),
        _TarjetaAsistente(
          emoji: '🚚',
          titulo: 'Asistente de rutas',
          descripcion:
              '¿Cómo distribuir tu mercadería desde tus almacenes/plantas hacia tus '
              'clientes al menor costo posible?',
          onTap: () => estado.pedirNavegacion(3),
        ),
        const SizedBox(height: 20),
        const Text('Prueba hablando o escribiendo', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
        const SizedBox(height: 6),
        const Text(
          'Toca el botón verde del micrófono (abajo). Ejemplos que puedes decir o escribir:',
          style: TextStyle(fontSize: 12.5, color: Colors.grey),
        ),
        const SizedBox(height: 6),
        const _ListaEjemplos([
          '"quiero optimizar mi producción de chompas y chalinas"',
          '"el hilo disponible es 500"',
          '"agrega el destino Puno con demanda 80"',
          '"resuelve" / "calcula"',
          '"léeme el resumen"',
          '"explícame en detalle técnico"',
        ]),
        const SizedBox(height: 80),
      ],
    );
  }
}

class _TarjetaAsistente extends StatelessWidget {
  final String emoji;
  final String titulo;
  final String descripcion;
  final VoidCallback onTap;
  const _TarjetaAsistente({
    required this.emoji,
    required this.titulo,
    required this.descripcion,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFF7FBFF),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 30)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titulo, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
                    const SizedBox(height: 4),
                    Text(descripcion, style: const TextStyle(fontSize: 12.5, color: Colors.black87)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppTheme.azulPrincipal),
            ],
          ),
        ),
      ),
    );
  }
}

class _ListaEjemplos extends StatelessWidget {
  final List<String> items;
  const _ListaEjemplos(this.items);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items
          .map((t) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('• $t', style: const TextStyle(fontSize: 12.5)),
              ))
          .toList(),
    );
  }
}
