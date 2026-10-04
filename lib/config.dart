/// Configuración central de la app.
/// El usuario solo debe completar estos valores para conectar los servicios.
class AppConfig {
  // ── Supabase ──────────────────────────────────────────────────────
  static const String supabaseUrl = 'TU_SUPABASE_URL';
  static const String supabaseAnonKey = 'TU_SUPABASE_ANON_KEY';

  // ── Gemini ────────────────────────────────────────────────────────
  static const String geminiApiKey = 'TU_GEMINI_API_KEY';
  static const String geminiModel = 'gemini-2.0-flash';

  // ── Google Cloud TTS (se llama vía Supabase Edge Function) ───────
  // La clave se almacena como secreto en Supabase, no aquí.
  static const String ttsEdgeFunctionName = 'text-to-speech';

  // ── Vosk ──────────────────────────────────────────────────────────
  static const String voskModelPath = 'assets/vosk/vosk-model-small-es-0.42';

  // ── App ───────────────────────────────────────────────────────────
  static const String appName = 'Asistente de Decisiones';
  static const String appVersion = '1.0.0';
  static const int monteCarloRuns = 500;
  static const int maxVariables = 500;
  static const int maxRestricciones = 1000;
}
