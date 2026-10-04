import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import 'burbuja_mensaje.dart';

/// Panel del asistente: se abre como una hoja inferior (bottom sheet),
/// igual que el Asistente de Google o Siri al tocar su botón — un patrón
/// mundialmente conocido para "hablar con un asistente" sin abandonar la
/// pantalla en la que el usuario está.
class PanelAsistente extends StatefulWidget {
  const PanelAsistente({super.key});

  @override
  State<PanelAsistente> createState() => _PanelAsistenteState();
}

class _PanelAsistenteState extends State<PanelAsistente> {
  final _controlador = TextEditingController();
  final _scrollCtrl = ScrollController();

  void _enviar(AppState estado) {
    final texto = _controlador.text.trim();
    if (texto.isEmpty) return;
    estado.procesarComandoTexto(texto);
    _controlador.clear();
    _bajarScroll();
  }

  void _bajarScroll() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, estado, _) {
        _bajarScroll();
        return DraggableScrollableSheet(
          initialChildSize: 0.72,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollControllerHoja) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 8, 4),
                    child: Row(
                      children: [
                        const Icon(Icons.smart_toy_outlined, color: AppTheme.azulPrincipal),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text('Asistente de voz', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('Voz', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            Switch(
                              value: estado.vozActiva,
                              onChanged: (v) => estado.alternarVoz(v),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollCtrl,
                      padding: const EdgeInsets.all(14),
                      itemCount: estado.historial.length,
                      itemBuilder: (context, i) => BurbujaMensaje(mensaje: estado.historial[i]),
                    ),
                  ),
                  if (estado.transcripcionParcial.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '"${estado.transcripcionParcial}"',
                          style: const TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic),
                        ),
                      ),
                    ),
                  SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                      child: Row(
                        children: [
                          _BotonMicrofono(estado: estado),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _controlador,
                              decoration: const InputDecoration(
                                hintText: 'Escribe un comando… ej. "hilo disponible 500"',
                                isDense: true,
                              ),
                              onSubmitted: (_) => _enviar(estado),
                              textInputAction: TextInputAction.send,
                            ),
                          ),
                          const SizedBox(width: 6),
                          IconButton(
                            icon: const Icon(Icons.send, color: AppTheme.azulPrincipal),
                            onPressed: () => _enviar(estado),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _BotonMicrofono extends StatelessWidget {
  final AppState estado;
  const _BotonMicrofono({required this.estado});

  @override
  Widget build(BuildContext context) {
    final escuchando = estado.voice.escuchando;
    return GestureDetector(
      onTap: () {
        if (escuchando) {
          estado.detenerEscucha();
        } else {
          estado.iniciarEscucha();
        }
      },
      child: CircleAvatar(
        radius: 22,
        backgroundColor: escuchando ? AppTheme.rojoAlerta : AppTheme.verdeAccion,
        child: Icon(escuchando ? Icons.stop : Icons.mic, color: Colors.white),
      ),
    );
  }
}

/// Abre el panel del asistente como hoja inferior. Se llama desde el botón
/// flotante (FAB) de [HomeShell], visible en todas las pantallas.
void abrirPanelAsistente(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const PanelAsistente(),
  );
}
