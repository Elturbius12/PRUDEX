import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/guias_datos.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/fila_origen_destino.dart';
import '../widgets/hoja_guia.dart';
import '../widgets/matriz_costos.dart';
import '../widgets/tarjeta_resultado_rutas.dart';

/// Asistente de rutas — Caso de uso 2 (sección 3.2): problema de
/// transporte. Minimiza el costo total de distribución respetando la
/// oferta de cada origen y la demanda de cada destino.
class RutasScreen extends StatelessWidget {
  const RutasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final estado = context.watch<AppState>();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Minimizar costo = Σ Σ (costo × cantidad enviada), respetando la oferta de cada '
          'origen y la demanda de cada destino.',
          style: TextStyle(fontSize: 12.5, color: Colors.grey),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Orígenes', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
            TextButton.icon(
              onPressed: estado.agregarOrigen,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Agregar'),
            ),
          ],
        ),
        ...estado.origenes.asMap().entries.map(
              (e) => FilaOrigenDestino(
                key: ValueKey('origen_${e.key}'),
                nombre: e.value.nombre,
                valor: e.value.oferta,
                etiquetaValor: 'Oferta',
                onCambioNombre: (v) => estado.actualizarOrigenCampo(e.key, 'nombre', v),
                onCambioValor: (v) => estado.actualizarOrigenCampo(e.key, 'oferta', v),
                onQuitar: () => estado.quitarOrigen(e.key),
              ),
            ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Destinos', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
            TextButton.icon(
              onPressed: estado.agregarDestino,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Agregar'),
            ),
          ],
        ),
        ...estado.destinos.asMap().entries.map(
              (e) => FilaOrigenDestino(
                key: ValueKey('destino_${e.key}'),
                nombre: e.value.nombre,
                valor: e.value.demanda,
                etiquetaValor: 'Demanda',
                onCambioNombre: (v) => estado.actualizarDestinoCampo(e.key, 'nombre', v),
                onCambioValor: (v) => estado.actualizarDestinoCampo(e.key, 'demanda', v),
                onQuitar: () => estado.quitarDestino(e.key),
              ),
            ),
        TextButton.icon(
          onPressed: () => mostrarGuia(context, guiasDatos['demanda_estimada']!),
          icon: const Icon(Icons.help_outline, size: 16),
          label: const Text('¿No sabes la demanda?', style: TextStyle(fontSize: 12)),
        ),
        const Divider(height: 24),
        const Text('Matriz de costos por ruta (origen → destino)',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
        const SizedBox(height: 8),
        MatrizCostos(
          origenes: estado.origenes,
          destinos: estado.destinos,
          costos: estado.costos,
          onCambio: estado.actualizarCosto,
        ),
        TextButton.icon(
          onPressed: () => mostrarGuia(context, guiasDatos['costo_ruta']!),
          icon: const Icon(Icons.help_outline, size: 16),
          label: const Text('¿No sabes el costo de una ruta?', style: TextStyle(fontSize: 12)),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: estado.resolverRutas,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Resolver'),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: estado.cargarEjemploRutas,
              child: const Text('Cargar ejemplo', style: TextStyle(fontSize: 12.5)),
            ),
            const SizedBox(width: 8),
            if (estado.resumenHabladoRutas != null)
              IconButton(
                tooltip: 'Escuchar resumen',
                icon: const Icon(Icons.volume_up, color: AppTheme.azulPrincipal),
                onPressed: () => estado.voice.hablar(estado.resumenHabladoRutas!),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (estado.resultadoRutas != null)
          TarjetaResultadoRutas(
            resultado: estado.resultadoRutas!,
            origenes: estado.origenesUsadosRuta,
            destinos: estado.destinosUsadosRuta,
            notaBalance: estado.notaBalanceRutas,
          ),
        const SizedBox(height: 80),
      ],
    );
  }
}
