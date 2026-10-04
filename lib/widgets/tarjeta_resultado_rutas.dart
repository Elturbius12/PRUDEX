import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/lp_models.dart';
import '../models/mensaje_chat.dart';
import '../models/origen_destino.dart';
import '../services/explicacion_service.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import 'selector_nivel.dart';
import 'tabla_trace.dart';

/// Tarjeta de resultado del Asistente de rutas — misma filosofía que la de
/// producción: el costo total primero, la matriz de envío después, y el
/// detalle técnico solo si el usuario lo pide.
class TarjetaResultadoRutas extends StatelessWidget {
  final ResultadoLP resultado;
  final List<Origen> origenes;
  final List<Destino> destinos;
  final String? notaBalance;

  const TarjetaResultadoRutas({
    super.key,
    required this.resultado,
    required this.origenes,
    required this.destinos,
    required this.notaBalance,
  });

  @override
  Widget build(BuildContext context) {
    final estado = context.watch<AppState>();

    if (resultado.estado != EstadoSolucion.optimo) {
      return Card(
        color: const Color(0xFFFDECEA),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Text('⚠ No se pudo resolver (${resultado.estado.name}). Revisa oferta, demanda y costos.',
              style: const TextStyle(fontSize: 13)),
        ),
      );
    }

    final narrativa = ExplicacionService.narrativaRutas(resultado, origenes, destinos, notaBalance);
    final sensibilidad = ExplicacionService.sensibilidadRutas(resultado, origenes);
    final nD = destinos.length;

    return Card(
      color: const Color(0xFFF7FBFF),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Resultado', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
            const SizedBox(height: 4),
            Text('Costo mínimo: S/. ${ExplicacionService.redondearTxt(resultado.z)}',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppTheme.azulOscuro)),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Table(
                border: TableBorder.all(color: Colors.grey.shade300),
                defaultColumnWidth: const FixedColumnWidth(90),
                children: [
                  TableRow(
                    decoration: const BoxDecoration(color: Color(0xFFEEF4FB)),
                    children: [
                      _cel('Origen \\ Destino', negrita: true, ancho: 130),
                      for (final d in destinos) _cel(d.nombre, negrita: true),
                    ],
                  ),
                  for (var i = 0; i < origenes.length; i++)
                    TableRow(children: [
                      _cel(origenes[i].nombre, negrita: true, ancho: 130),
                      for (var j = 0; j < nD; j++) _cel(_valorEnvio(i, j, nD)),
                    ]),
                ],
              ),
            ),
            if (notaBalance != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E6),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFF0D98C)),
                ),
                child: Text(notaBalance!, style: const TextStyle(fontSize: 12, color: Color(0xFF6B5300))),
              ),
            ],
            const SizedBox(height: 12),
            SelectorNivel(nivel: estado.nivelExplicacion, onCambio: estado.cambiarNivelExplicacion),
            const SizedBox(height: 8),
            if (estado.nivelExplicacion == NivelExplicacion.ejecutivo) ...[
              Text(narrativa, style: const TextStyle(fontSize: 13, height: 1.4)),
              const SizedBox(height: 8),
              const Text('Análisis de sensibilidad automático:', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
              Text(sensibilidad, style: const TextStyle(fontSize: 12.5, height: 1.4)),
            ] else ...[
              Text('Modelo de transporte resuelto por Simplex (Big M) en ${resultado.iteraciones} iteración(es).',
                  style: const TextStyle(fontSize: 12.5, fontStyle: FontStyle.italic)),
              const SizedBox(height: 8),
              TablaTrace(resultado: resultado),
            ],
          ],
        ),
      ),
    );
  }

  String _valorEnvio(int i, int j, int nD) {
    final valor = resultado.x[i * nD + j];
    return valor > 1e-6 ? ExplicacionService.redondearTxt(valor) : '—';
  }

  Widget _cel(String texto, {bool negrita = false, double? ancho}) {
    return Container(
      width: ancho,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: Text(texto,
          style: TextStyle(fontSize: 12, fontWeight: negrita ? FontWeight.w700 : FontWeight.normal)),
    );
  }
}
