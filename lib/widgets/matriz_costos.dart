import 'package:flutter/material.dart';
import '../models/origen_destino.dart';

/// Matriz de costos origen→destino editable, en formato de hoja de
/// cálculo (Google Sheets/Excel) con scroll horizontal — el formato más
/// reconocible para una tabla de datos que el usuario espera "llenar".
class MatrizCostos extends StatelessWidget {
  final List<Origen> origenes;
  final List<Destino> destinos;
  final List<List<double>> costos;
  final void Function(int i, int j, String valor) onCambio;

  const MatrizCostos({
    super.key,
    required this.origenes,
    required this.destinos,
    required this.costos,
    required this.onCambio,
  });

  @override
  Widget build(BuildContext context) {
    if (origenes.isEmpty || destinos.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text('Agrega al menos un origen y un destino para editar los costos.',
            style: TextStyle(fontSize: 12.5, color: Colors.grey)),
      );
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Table(
        border: TableBorder.all(color: Colors.grey.shade300),
        defaultColumnWidth: const FixedColumnWidth(96),
        children: [
          TableRow(
            decoration: const BoxDecoration(color: Color(0xFFEEF4FB)),
            children: [
              _cabecera('Origen \\ Destino', ancho: 140),
              for (final d in destinos) _cabecera(d.nombre),
            ],
          ),
          for (var i = 0; i < origenes.length; i++)
            TableRow(children: [
              _cabecera(origenes[i].nombre, ancho: 140),
              for (var j = 0; j < destinos.length; j++) _celdaEditable(i, j),
            ]),
        ],
      ),
    );
  }

  Widget _cabecera(String texto, {double? ancho}) {
    return Container(
      width: ancho,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Text(texto, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
    );
  }

  Widget _celdaEditable(int i, int j) {
    final valor = (i < costos.length && j < costos[i].length) ? costos[i][j] : 0.0;
    final texto = valor == valor.roundToDouble() ? valor.toInt().toString() : valor.toString();
    final controlador = TextEditingController(text: texto);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: TextField(
        controller: controlador,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 12.5),
        decoration: const InputDecoration(isDense: true, border: InputBorder.none),
        onSubmitted: (v) => onCambio(i, j, v),
        onTapOutside: (_) => onCambio(i, j, controlador.text),
      ),
    );
  }
}
