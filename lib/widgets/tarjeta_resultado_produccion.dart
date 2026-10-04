import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/lp_models.dart';
import '../models/mensaje_chat.dart';
import '../models/producto.dart';
import '../services/explicacion_service.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import 'selector_nivel.dart';
import 'tabla_trace.dart';

/// Tarjeta de resultado del Asistente de producción — número grande +
/// acción, como una app de billetera digital (Yape/Plin) o de banca móvil:
/// lo primero que el usuario ve es "cuánto", no la matemática detrás.
class TarjetaResultadoProduccion extends StatelessWidget {
  final ResultadoLP resultado;
  final List<Producto> productos;
  const TarjetaResultadoProduccion({super.key, required this.resultado, required this.productos});

  @override
  Widget build(BuildContext context) {
    final estado = context.watch<AppState>();

    if (resultado.estado == EstadoSolucion.infactible) {
      return _avisoError(
          '⚠ No hay combinación factible. Revisa que las demandas mínimas comprometidas '
          'no superen tu hilo o tiempo disponible.');
    }
    if (resultado.estado == EstadoSolucion.noAcotado) {
      return _avisoError('⚠ El problema no está acotado. Probablemente falta una demanda máxima en algún producto.');
    }

    final narrativa = ExplicacionService.narrativaProduccion(resultado, productos);
    final sensibilidad = ExplicacionService.sensibilidadProduccion(resultado);
    final cuello = ExplicacionService.cuelloBottellaProduccion(resultado);

    return Card(
      color: const Color(0xFFF7FBFF),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Resultado', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
            const SizedBox(height: 4),
            Text('Utilidad óptima: S/. ${ExplicacionService.redondearTxt(resultado.z)}',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppTheme.azulOscuro)),
            const SizedBox(height: 10),
            Table(
              border: TableBorder.all(color: Colors.grey.shade300),
              children: [
                const TableRow(
                  decoration: BoxDecoration(color: Color(0xFFEEF4FB)),
                  children: [_Celda('Producto', esCabecera: true), _Celda('Cantidad óptima', esCabecera: true)],
                ),
                for (var i = 0; i < resultado.nombresVariables.length; i++)
                  TableRow(children: [
                    _Celda(resultado.nombresVariables[i]),
                    _Celda(ExplicacionService.redondearTxt(resultado.x[i])),
                  ]),
              ],
            ),
            const SizedBox(height: 8),
            Text('Cuello de botella (recurso 100% usado): $cuello',
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 12),
            SelectorNivel(
              nivel: estado.nivelExplicacion,
              onCambio: estado.cambiarNivelExplicacion,
            ),
            const SizedBox(height: 8),
            if (estado.nivelExplicacion == NivelExplicacion.ejecutivo) ...[
              Text(narrativa, style: const TextStyle(fontSize: 13, height: 1.4)),
              const SizedBox(height: 8),
              Text('Análisis de sensibilidad automático:',
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
              Text(sensibilidad, style: const TextStyle(fontSize: 12.5, height: 1.4)),
            ] else ...[
              Text(
                'Modelo resuelto por Simplex (Big M) en ${resultado.iteraciones} iteración(es).',
                style: const TextStyle(fontSize: 12.5, fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 8),
              TablaTrace(resultado: resultado),
            ],
          ],
        ),
      ),
    );
  }

  Widget _avisoError(String texto) {
    return Card(
      color: const Color(0xFFFDECEA),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Text(texto, style: const TextStyle(fontSize: 13)),
      ),
    );
  }
}

class _Celda extends StatelessWidget {
  final String texto;
  final bool esCabecera;
  const _Celda(this.texto, {this.esCabecera = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Text(
        texto,
        style: TextStyle(fontSize: 12.5, fontWeight: esCabecera ? FontWeight.w700 : FontWeight.normal),
      ),
    );
  }
}
