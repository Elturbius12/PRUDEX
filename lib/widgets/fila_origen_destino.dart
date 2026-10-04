import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Fila editable genérica para un origen o un destino (nombre + un valor
/// numérico). Mismo patrón de lista editable que una app de contactos o
/// una lista de tareas: nombre a la izquierda, dato a la derecha, borrar
/// al final.
class FilaOrigenDestino extends StatelessWidget {
  final String nombre;
  final double valor;
  final String etiquetaValor;
  final void Function(String nombre) onCambioNombre;
  final void Function(String valor) onCambioValor;
  final VoidCallback onQuitar;

  const FilaOrigenDestino({
    super.key,
    required this.nombre,
    required this.valor,
    required this.etiquetaValor,
    required this.onCambioNombre,
    required this.onCambioValor,
    required this.onQuitar,
  });

  @override
  Widget build(BuildContext context) {
    final nombreCtrl = TextEditingController(text: nombre);
    final valorTexto = valor == valor.roundToDouble() ? valor.toInt().toString() : valor.toString();
    final valorCtrl = TextEditingController(text: valorTexto);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: TextField(
                controller: nombreCtrl,
                style: const TextStyle(fontSize: 13),
                decoration: const InputDecoration(isDense: true, border: InputBorder.none),
                onSubmitted: onCambioNombre,
                onTapOutside: (_) => onCambioNombre(nombreCtrl.text),
              ),
            ),
            SizedBox(
              width: 90,
              child: TextField(
                controller: valorCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(isDense: true, hintText: etiquetaValor),
                onSubmitted: onCambioValor,
                onTapOutside: (_) => onCambioValor(valorCtrl.text),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 18, color: AppTheme.rojoAlerta),
              onPressed: onQuitar,
            ),
          ],
        ),
      ),
    );
  }
}
