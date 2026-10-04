import 'package:flutter/material.dart';
import '../models/mensaje_chat.dart';
import '../theme/app_theme.dart';

/// Interruptor de dos opciones (segmented control) — patrón usado en
/// prácticamente todas las apps de iOS/Android para alternar entre dos
/// vistas del mismo contenido (aquí: explicación ejecutiva vs. técnica).
class SelectorNivel extends StatelessWidget {
  final NivelExplicacion nivel;
  final ValueChanged<NivelExplicacion> onCambio;
  const SelectorNivel({super.key, required this.nivel, required this.onCambio});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _opcion('Nivel ejecutivo', NivelExplicacion.ejecutivo),
        const SizedBox(width: 6),
        _opcion('Nivel técnico', NivelExplicacion.tecnico),
      ],
    );
  }

  Widget _opcion(String etiqueta, NivelExplicacion valor) {
    final activo = nivel == valor;
    return GestureDetector(
      onTap: () => onCambio(valor),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: activo ? AppTheme.azulPrincipal : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: activo ? AppTheme.azulPrincipal : Colors.grey.shade300),
        ),
        child: Text(
          etiqueta,
          style: TextStyle(fontSize: 12, color: activo ? Colors.white : Colors.black87),
        ),
      ),
    );
  }
}
