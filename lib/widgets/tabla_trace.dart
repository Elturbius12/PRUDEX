import 'package:flutter/material.dart';
import '../models/lp_models.dart';
import '../services/explicacion_service.dart';

/// Muestra el trace del Simplex (tabla por iteración) y los precios sombra
/// — el detalle "iteración por iteración" que pide el nivel técnico
/// (sección 10.2 del documento). Usa una fuente monoespaciada dentro de un
/// contenedor con scroll horizontal, como una hoja de cálculo o una
/// consola: es el formato más claro para una tabla numérica ancha en una
/// pantalla de celular angosta.
class TablaTrace extends StatelessWidget {
  final ResultadoLP resultado;
  const TablaTrace({super.key, required this.resultado});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < resultado.trace.length; i++) _bloqueIteracion(i, resultado.trace[i]),
        const SizedBox(height: 10),
        const Text('Precios sombra (duales) por restricción:',
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        _tablaDuales(),
      ],
    );
  }

  Widget _bloqueIteracion(int i, PasoSimplex paso) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Iteración $i ${paso.entrante == null ? '(tabla inicial)' : '— ${paso.nota}'}',
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Table(
              border: TableBorder.all(color: Colors.grey.shade300),
              defaultColumnWidth: const IntrinsicColumnWidth(),
              children: [
                TableRow(
                  decoration: const BoxDecoration(color: Color(0xFFEEF4FB)),
                  children: [
                    _cel('Base', negrita: true),
                    ...resultado.nombresColumnas.map((c) => _cel(c, negrita: true)),
                    _cel('RHS', negrita: true),
                  ],
                ),
                for (var f = 0; f < paso.tabla.length; f++)
                  TableRow(children: [
                    _cel(paso.base[f]),
                    ...paso.tabla[f].map((v) => _cel(ExplicacionService.redondearTxt(v))),
                  ]),
                TableRow(
                  decoration: const BoxDecoration(color: Color(0xFFFDF6E3)),
                  children: [
                    _cel('Z', negrita: true),
                    ...paso.filaCosto.map((v) => _cel(ExplicacionService.redondearTxt(v))),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tablaDuales() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Table(
        border: TableBorder.all(color: Colors.grey.shade300),
        defaultColumnWidth: const IntrinsicColumnWidth(),
        children: [
          TableRow(
            decoration: const BoxDecoration(color: Color(0xFFEEF4FB)),
            children: [
              _cel('Restricción', negrita: true),
              _cel('RHS', negrita: true),
              _cel('Uso real', negrita: true),
              _cel('Holgura', negrita: true),
              _cel('Precio sombra', negrita: true),
            ],
          ),
          for (var i = 0; i < resultado.holguras.length; i++)
            TableRow(children: [
              _cel(resultado.holguras[i].etiqueta.isEmpty ? 'R${i + 1}' : resultado.holguras[i].etiqueta),
              _cel(ExplicacionService.redondearTxt(resultado.holguras[i].rhs)),
              _cel(ExplicacionService.redondearTxt(resultado.holguras[i].usado)),
              _cel(ExplicacionService.redondearTxt(resultado.holguras[i].holgura)),
              _cel(resultado.duales[i] == null ? '—' : ExplicacionService.redondearTxt(resultado.duales[i]!)),
            ]),
        ],
      ),
    );
  }

  Widget _cel(String texto, {bool negrita = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Text(
        texto,
        style: TextStyle(
          fontSize: 10.5,
          fontFamily: 'monospace',
          fontWeight: negrita ? FontWeight.w700 : FontWeight.normal,
        ),
      ),
    );
  }
}
