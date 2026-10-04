import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/guias_datos.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/hoja_guia.dart';
import '../widgets/producto_card.dart';
import '../widgets/tarjeta_resultado_produccion.dart';

/// Asistente de producción — Caso de uso 1 (sección 3.1): mezcla óptima de
/// producción textil. Maximiza utilidad respetando hilo, tiempo y demanda.
class ProduccionScreen extends StatelessWidget {
  const ProduccionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final estado = context.watch<AppState>();
    final hiloCtrl = TextEditingController(
        text: estado.hiloDisponible == estado.hiloDisponible.roundToDouble()
            ? estado.hiloDisponible.toInt().toString()
            : estado.hiloDisponible.toString());
    final tiempoCtrl = TextEditingController(
        text: estado.tiempoDisponible == estado.tiempoDisponible.roundToDouble()
            ? estado.tiempoDisponible.toInt().toString()
            : estado.tiempoDisponible.toString());

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Maximizar utilidad = Σ (utilidad × cantidad), sin exceder tu hilo, tu tiempo '
          'ni la demanda estimada de cada producto.',
          style: TextStyle(fontSize: 12.5, color: Colors.grey),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Productos', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
            TextButton.icon(
              onPressed: estado.agregarProducto,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Agregar'),
            ),
          ],
        ),
        ...estado.productos.asMap().entries.map(
              (e) => ProductoCard(
                key: ValueKey('producto_${e.key}_${e.value.hashCode}'),
                producto: e.value,
                onCambio: (campo, valor) => estado.actualizarProductoCampo(e.key, campo, valor),
                onQuitar: () => estado.quitarProducto(e.key),
              ),
            ),
        TextButton.icon(
          onPressed: () => mostrarGuia(context, guiasDatos['demanda_estimada']!),
          icon: const Icon(Icons.help_outline, size: 16),
          label: const Text('¿No sabes la demanda estimada?', style: TextStyle(fontSize: 12)),
        ),
        const Divider(height: 24),
        const Text('Recursos disponibles este período', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
        const SizedBox(height: 8),
        TextField(
          controller: hiloCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Hilo disponible (total)', isDense: true),
          onSubmitted: (v) => estado.setHiloDisponible(double.tryParse(v) ?? 0),
          onTapOutside: (_) => estado.setHiloDisponible(double.tryParse(hiloCtrl.text) ?? 0),
        ),
        TextButton.icon(
          onPressed: () => mostrarGuia(context, guiasDatos['hilo_disponible']!),
          icon: const Icon(Icons.help_outline, size: 16),
          label: const Text('¿No sabes cuánto hilo tienes?', style: TextStyle(fontSize: 12)),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: tiempoCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Tiempo disponible (horas)', isDense: true),
          onSubmitted: (v) => estado.setTiempoDisponible(double.tryParse(v) ?? 0),
          onTapOutside: (_) => estado.setTiempoDisponible(double.tryParse(tiempoCtrl.text) ?? 0),
        ),
        TextButton.icon(
          onPressed: () => mostrarGuia(context, guiasDatos['tiempo_disponible']!),
          icon: const Icon(Icons.help_outline, size: 16),
          label: const Text('¿No sabes tu tiempo disponible?', style: TextStyle(fontSize: 12)),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: estado.resolverProduccion,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Resolver'),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: estado.cargarEjemploProduccion,
              child: const Text('Cargar ejemplo', style: TextStyle(fontSize: 12.5)),
            ),
            const SizedBox(width: 8),
            if (estado.resumenHabladoProduccion != null)
              IconButton(
                tooltip: 'Escuchar resumen',
                icon: const Icon(Icons.volume_up, color: AppTheme.azulPrincipal),
                onPressed: () => estado.voice.hablar(estado.resumenHabladoProduccion!),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (estado.resultadoProduccion != null)
          TarjetaResultadoProduccion(resultado: estado.resultadoProduccion!, productos: estado.productos),
        const SizedBox(height: 80),
      ],
    );
  }
}
