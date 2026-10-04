import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:asistente_pl/state/app_state.dart';
import 'package:asistente_pl/theme/app_colors.dart';
import 'package:asistente_pl/models/lp_models.dart';
import 'package:asistente_pl/widgets/common_widgets.dart';
import 'package:asistente_pl/widgets/chat_bubble.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _textCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    // Mensaje de bienvenida si está vacío
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = context.read<AppState>();
      if (state.mensajesChat.isEmpty) {
        state.agregarMensajeBot(
          '¡Hola! Soy tu asistente de decisiones. '
          'Cuéntame sobre tu negocio y qué decisión necesitas tomar. '
          'Puedo ayudarte a optimizar producción, distribución, asignación de recursos y más.',
        );
        state.agregarMensajeBot(
          '',
          tipo: TipoMensaje.sugerencia,
          datos: {
            'sugerencias': [
              'Quiero maximizar mis ganancias',
              'Necesito reducir costos de envío',
              'Tengo un problema de asignación',
              'Quiero importar datos de Excel',
            ]
          },
        );
      }
    });
  }

  void _enviar() {
    final texto = _textCtrl.text.trim();
    if (texto.isEmpty) return;
    _textCtrl.clear();
    context.read<AppState>().enviarMensaje(texto);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 200), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _toggleVoz() async {
    final state = context.read<AppState>();
    if (_isListening) {
      state.voice.stopListening();
      setState(() => _isListening = false);
    } else {
      setState(() => _isListening = true);
      await state.voice.startListening(
        onResult: (texto) {
          _textCtrl.text = texto;
          setState(() => _isListening = false);
        },
      );
    }
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mensajes = state.mensajesChat;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Asistente de Decisiones'),
        actions: [
          // Indicador de modo
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(state.esEstudiante ? 'Estudiante' : 'Mi negocio'),
              selected: true,
              onSelected: (_) {
                state.setModo(state.esEstudiante ? 'negocio' : 'estudiante');
              },
              selectedColor: AppColors.turquesa.withAlpha(40),
              labelStyle: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.turquesa : AppColors.turquesaOscuro,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Mensajes ─────────────────────────────────────────
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              itemCount: mensajes.length,
              itemBuilder: (context, i) {
                final m = mensajes[i];
                return ChatBubble(
                  mensaje: m,
                  onSugerencia: (texto) {
                    _textCtrl.text = texto;
                    _enviar();
                  },
                );
              },
            ),
          ),

          // ── Barra de entrada ─────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkPanel : AppColors.lightPanel,
              border: Border(
                top: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  // Botón micrófono
                  MicButton(
                    isListening: _isListening,
                    onPressed: _toggleVoz,
                  ),
                  const SizedBox(width: 10),
                  // Campo de texto
                  Expanded(
                    child: TextField(
                      controller: _textCtrl,
                      maxLines: 3,
                      minLines: 1,
                      textCapitalization: TextCapitalization.sentences,
                      style: TextStyle(
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Describe tu problema...',
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      onSubmitted: (_) => _enviar(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Botón enviar
                  IconButton(
                    onPressed: _enviar,
                    icon: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.turquesa,
                      ),
                      child: const Icon(Icons.send, color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
