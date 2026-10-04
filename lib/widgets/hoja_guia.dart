import 'package:flutter/material.dart';
import '../data/guias_datos.dart';

/// Guía de captura de datos (sección 9.3) mostrada como hoja inferior —
/// el mismo patrón de "ayuda contextual" que Gmail o Google Maps usan
/// para no sacar al usuario de la pantalla en la que está.
void mostrarGuia(BuildContext context, GuiaDato guia) {
  showModalBottomSheet(
    context: context,
    builder: (context) => Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb_outline, color: Colors.amber),
              const SizedBox(width: 8),
              Expanded(
                child: Text(guia.titulo, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(guia.texto, style: const TextStyle(fontSize: 13.5, height: 1.4)),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Entendido'),
            ),
          ),
        ],
      ),
    ),
  );
}
