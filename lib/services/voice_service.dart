import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:asistente_pl/config.dart';

/// Servicio de voz: Vosk para entrada (offline), Cloud TTS para salida.
class VoiceService extends ChangeNotifier {
  bool _isListening = false;
  bool _isSpeaking = false;
  String _textoReconocido = '';
  bool _voskDisponible = false;
  final AudioPlayer _player = AudioPlayer();

  bool get isListening => _isListening;
  bool get isSpeaking => _isSpeaking;
  String get textoReconocido => _textoReconocido;
  bool get voskDisponible => _voskDisponible;

  /// Inicializa Vosk con el modelo en español.
  Future<void> init() async {
    try {
      // Vosk se inicializa cuando el plugin está disponible
      // El modelo debe estar en assets/vosk/
      _voskDisponible = true; // Se verificará en runtime
    } catch (e) {
      _voskDisponible = false;
      debugPrint('Vosk no disponible: $e');
    }
  }

  /// Inicia reconocimiento de voz con Vosk (offline).
  Future<void> startListening({
    required Function(String texto) onResult,
    Function(String parcial)? onPartial,
  }) async {
    if (_isListening) return;

    _isListening = true;
    _textoReconocido = '';
    notifyListeners();

    // Placeholder: Vosk se conecta aquí
    // En producción, usar vosk_flutter:
    // final vosk = VoskFlutterPlugin.instance();
    // final model = await vosk.createModel(AppConfig.voskModelPath);
    // final recognizer = await vosk.createRecognizer(model: model, sampleRate: 16000);
    // recognizer.onResult().listen((event) {
    //   final data = jsonDecode(event);
    //   _textoReconocido = data['text'] ?? '';
    //   onResult(_textoReconocido);
    // });

    // Simulación para desarrollo
    await Future.delayed(const Duration(seconds: 2));
    if (_isListening) {
      _textoReconocido = '';
      _isListening = false;
      notifyListeners();
    }
  }

  /// Detiene el reconocimiento de voz.
  void stopListening() {
    _isListening = false;
    notifyListeners();
  }

  /// Lee texto en voz alta usando Google Cloud TTS (vía Supabase Edge Function).
  Future<void> hablar(String texto, {String? supabaseUrl, String? anonKey}) async {
    if (_isSpeaking) {
      await detenerHabla();
    }

    _isSpeaking = true;
    notifyListeners();

    try {
      final url = supabaseUrl ?? AppConfig.supabaseUrl;
      final key = anonKey ?? AppConfig.supabaseAnonKey;

      if (url == 'TU_SUPABASE_URL') {
        // Sin Supabase, no hay TTS
        _isSpeaking = false;
        notifyListeners();
        return;
      }

      final resp = await http.post(
        Uri.parse('$url/functions/v1/${AppConfig.ttsEdgeFunctionName}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $key',
        },
        body: jsonEncode({
          'text': texto,
          'languageCode': 'es-US',
          'voiceName': 'es-US-Wavenet-B',
        }),
      ).timeout(const Duration(seconds: 10));

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final audioBase64 = data['audioContent'] as String?;
        if (audioBase64 != null) {
          final bytes = base64Decode(audioBase64);
          final dir = await getTemporaryDirectory();
          final file = File('${dir.path}/tts_output.mp3');
          await file.writeAsBytes(bytes);
          await _player.play(DeviceFileSource(file.path));
          _player.onPlayerComplete.listen((_) {
            _isSpeaking = false;
            notifyListeners();
          });
          return;
        }
      }
    } catch (e) {
      debugPrint('TTS error: $e');
    }

    _isSpeaking = false;
    notifyListeners();
  }

  /// Detiene la reproducción de voz.
  Future<void> detenerHabla() async {
    await _player.stop();
    _isSpeaking = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
