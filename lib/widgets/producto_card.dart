import 'package:flutter/material.dart';
import '../models/producto.dart';
import '../theme/app_theme.dart';

/// Tarjeta editable de un producto — patrón de "fila de hoja de cálculo"
/// (Google Sheets / Excel) pero en tarjetas apilables, más cómodo en
/// pantalla de celular que una tabla ancha.
class ProductoCard extends StatelessWidget {
  final Producto producto;
  final void Function(String campo, String valor) onCambio;
  final VoidCallback onQuitar;

  const ProductoCard({
    super.key,
    required this.producto,
    required this.onCambio,
    required this.onQuitar,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _campoTexto('Nombre', producto.nombre, (v) => onCambio('nombre', v)),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppTheme.rojoAlerta, size: 20),
                  onPressed: onQuitar,
                  tooltip: 'Quitar producto',
                ),
              ],
            ),
            Row(
              children: [
                Expanded(child: _campoNum('Utilidad/u (S/.)', producto.utilidad, (v) => onCambio('utilidad', v))),
                const SizedBox(width: 8),
                Expanded(child: _campoNum('Hilo/u', producto.hilo, (v) => onCambio('hilo', v))),
              ],
            ),
            Row(
              children: [
                Expanded(child: _campoNum('Tiempo/u (h)', producto.tiempo, (v) => onCambio('tiempo', v))),
                const SizedBox(width: 8),
                Expanded(child: _campoNum('Demanda estimada', producto.demanda, (v) => onCambio('demanda', v))),
              ],
            ),
            _campoNum('Demanda mínima (compromisos, 0 = ninguno)', producto.demandaMinima,
                (v) => onCambio('demandaMinima', v)),
          ],
        ),
      ),
    );
  }

  Widget _campoTexto(String etiqueta, String valor, ValueChanged<String> onChanged) {
    return _campoBase(etiqueta, TextEditingController(text: valor), TextInputType.text, onChanged);
  }

  Widget _campoNum(String etiqueta, double valor, ValueChanged<String> onChanged) {
    final texto = valor == valor.roundToDouble() ? valor.toInt().toString() : valor.toString();
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: _campoBase(etiqueta, TextEditingController(text: texto), TextInputType.number, onChanged),
    );
  }

  Widget _campoBase(
    String etiqueta,
    TextEditingController controlador,
    TextInputType tipo,
    ValueChanged<String> onChanged,
  ) {
    return TextField(
      controller: controlador,
      keyboardType: tipo,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        labelText: etiqueta,
        labelStyle: const TextStyle(fontSize: 11.5),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
      onSubmitted: onChanged,
      onTapOutside: (_) => onChanged(controlador.text),
    );
  }
}
