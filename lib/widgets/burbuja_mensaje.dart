import 'package:flutter/material.dart';
import '../models/mensaje_chat.dart';
import '../theme/app_theme.dart';

/// Burbuja de chat — mismo patrón visual que WhatsApp / Telegram / el
/// Asistente de Google: mensajes del usuario a la derecha, respuestas del
/// asistente a la izquierda. Es el patrón más reconocible mundialmente
/// para una conversación por turnos, así que no requiere explicación.
class BurbujaMensaje extends StatelessWidget {
  final MensajeChat mensaje;
  const BurbujaMensaje({super.key, required this.mensaje});

  @override
  Widget build(BuildContext context) {
    final esUsuario = mensaje.autor == AutorMensaje.usuario;
    return Align(
      alignment: esUsuario ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: esUsuario ? AppTheme.azulPrincipal.withOpacity(0.12) : Colors.grey.shade100,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(14),
            topRight: const Radius.circular(14),
            bottomLeft: Radius.circular(esUsuario ? 14 : 2),
            bottomRight: Radius.circular(esUsuario ? 2 : 14),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              esUsuario ? 'Tú' : 'Asistente',
              style: TextStyle(fontSize: 10.5, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 2),
            Text(mensaje.texto, style: const TextStyle(fontSize: 13.5, height: 1.3)),
          ],
        ),
      ),
    );
  }
}
