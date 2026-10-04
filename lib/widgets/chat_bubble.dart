import 'package:flutter/material.dart';
import 'package:asistente_pl/theme/app_colors.dart';
import 'package:asistente_pl/models/lp_models.dart';
import 'package:asistente_pl/widgets/common_widgets.dart';

class ChatBubble extends StatelessWidget {
  final MensajeChat mensaje;
  final Function(String)? onSugerencia;

  const ChatBubble({super.key, required this.mensaje, this.onSugerencia});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Indicador de carga
    if (mensaje.tipo == TipoMensaje.cargando) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(
                          isDark ? AppColors.turquesa : AppColors.turquesaOscuro),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Analizando...',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Chips de sugerencias
    if (mensaje.tipo == TipoMensaje.sugerencia) {
      final sugerencias =
          (mensaje.datos?['sugerencias'] as List?)?.cast<String>() ?? [];
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Wrap(
          spacing: 8,
          runSpacing: 6,
          children: sugerencias.map((s) {
            return ActionChip(
              label: Text(s, style: const TextStyle(fontSize: 13)),
              backgroundColor: isDark
                  ? AppColors.turquesa.withAlpha(20)
                  : AppColors.turquesaOscuro.withAlpha(15),
              side: BorderSide(
                color: isDark
                    ? AppColors.turquesa.withAlpha(60)
                    : AppColors.turquesaOscuro.withAlpha(40),
              ),
              onPressed: () => onSugerencia?.call(s),
            );
          }).toList(),
        ),
      );
    }

    // Resultado con semáforo
    if (mensaje.tipo == TipoMensaje.resultado && mensaje.datos != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.auto_graph, color: AppColors.turquesa, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Recomendación',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Decisión
              Text(
                mensaje.datos!['decision'] as String? ?? '',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              // Impacto
              Text(
                mensaje.datos!['impacto'] as String? ?? '',
                style: TextStyle(
                  fontSize: 15,
                  color: isDark ? AppColors.ambar : AppColors.ambar,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              // Confianza
              SemaforoIndicator(
                confianza: (mensaje.datos!['confianza'] as num?)?.toDouble() ?? 0.5,
              ),
              const SizedBox(height: 10),
              // Explicación
              Text(
                mensaje.texto,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Burbuja normal
    final esUsuario = mensaje.esUsuario;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
            esUsuario ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!esUsuario)
            Padding(
              padding: const EdgeInsets.only(right: 8, top: 4),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: isDark ? AppColors.turquesa : AppColors.turquesaOscuro,
                child: const Icon(Icons.auto_graph, size: 16, color: Colors.white),
              ),
            ),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: esUsuario
                    ? (isDark ? AppColors.turquesa.withAlpha(30) : AppColors.turquesaOscuro.withAlpha(20))
                    : (isDark ? AppColors.darkSurface : AppColors.lightSurface),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(esUsuario ? 16 : 4),
                  bottomRight: Radius.circular(esUsuario ? 4 : 16),
                ),
                border: esUsuario
                    ? Border.all(
                        color: isDark
                            ? AppColors.turquesa.withAlpha(40)
                            : AppColors.turquesaOscuro.withAlpha(30))
                    : null,
              ),
              child: Text(
                mensaje.texto,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.45,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
            ),
          ),
          if (esUsuario) const SizedBox(width: 40),
        ],
      ),
    );
  }
}
