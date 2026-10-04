# Asistente de Decisiones para Emprendedores

Aplicación multiplataforma (Android + Windows) que ayuda a emprendedores y estudiantes a tomar decisiones óptimas usando **programación lineal** e **inteligencia artificial conversacional**.

## Requisitos

- Flutter **3.47.6** (stable)
- Dart **3.13.5**
- Android Studio / VS Code con extensión Flutter

## Inicio rápido

```bash
# 1. Obtener dependencias
flutter pub get

# 2. Ejecutar en modo debug
flutter run
```

## Configurar las APIs

Abre `lib/config.dart` y reemplaza los valores placeholder:

```dart
static const supabaseUrl = 'TU_SUPABASE_URL';       // → URL de tu proyecto Supabase
static const supabaseAnonKey = 'TU_SUPABASE_ANON_KEY'; // → Anon key de Supabase
static const geminiApiKey = 'TU_GEMINI_API_KEY';     // → API key de Google AI Studio
```

### Supabase (gratis)

1. Crea un proyecto en [supabase.com](https://supabase.com)
2. Copia la URL y la Anon Key desde **Settings → API**
3. Habilita **Authentication → Email** en el dashboard

### Gemini AI (gratis)

1. Ve a [aistudio.google.com](https://aistudio.google.com)
2. Crea una API key
3. El modelo usado es `gemini-2.0-flash` (gratuito)

### Voz offline (Vosk)

1. Descarga el modelo español pequeño desde [alphacephei.com/vosk/models](https://alphacephei.com/vosk/models)
2. Colócalo en `assets/vosk-model/` y registra la carpeta en `pubspec.yaml`

### Síntesis de voz (TTS)

Requiere una Edge Function en Supabase que llame a Google Cloud TTS. Configura `ttsEdgeFunctionName` en `config.dart`.

## Sin APIs configuradas

La app funciona **sin conexión a internet**:
- El solver de programación lineal es 100% local
- El chat usa un NLU básico por regex como respaldo
- Solo la IA conversacional (Gemini), la autenticación (Supabase) y la voz (TTS) requieren conexión

## Arquitectura

```
lib/
├── config.dart              # Configuración central y API keys
├── main.dart                # Punto de entrada
├── core/                    # Motores de cálculo
│   ├── simplex_solver.dart      # Simplex dos fases + análisis sensibilidad
│   ├── branch_bound_solver.dart # Branch & Bound (variables enteras)
│   ├── grafico_solver.dart      # Método gráfico (2 variables)
│   ├── transporte_solver.dart   # Transporte (Vogel + MODI)
│   ├── hungaro_solver.dart      # Asignación (Húngaro)
│   ├── montecarlo_solver.dart   # Simulación Monte Carlo
│   ├── solver_engine.dart       # Motor central (selección automática)
│   └── explicacion_service.dart # Generador de explicaciones
├── models/
│   └── lp_models.dart       # Modelos de datos (ProblemaLP, ResultadoLP, etc.)
├── services/
│   ├── database_service.dart    # Persistencia local (SharedPreferences)
│   ├── gemini_service.dart      # NLU con Gemini AI
│   ├── voice_service.dart       # Voz: Vosk (input) + TTS (output)
│   ├── supabase_service.dart    # Auth + datos de mercado
│   └── excel_service.dart       # Importación Excel/CSV
├── state/
│   ├── app_state.dart       # Estado central (Provider)
│   └── theme_state.dart     # Tema oscuro/claro
├── theme/
│   ├── app_colors.dart      # Paleta de colores
│   └── app_theme.dart       # ThemeData completo
├── screens/
│   ├── splash_screen.dart   # Pantalla de carga animada
│   ├── login_screen.dart    # Login con engranajes animados
│   ├── home_screen.dart     # Navegación principal (4 tabs)
│   ├── chat_screen.dart     # Asistente conversacional
│   ├── modelo_screen.dart   # Constructor de modelos LP
│   ├── resultados_screen.dart # Visualización de resultados
│   └── config_screen.dart   # Ajustes y perfil
└── widgets/
    ├── common_widgets.dart  # Componentes reutilizables
    ├── chat_bubble.dart     # Burbujas de chat
    └── gear_painter.dart    # Pintor de engranajes animados
```

## Funcionalidades

- **Chat inteligente**: describe tu problema y el asistente construye el modelo matemático
- **6 métodos de solución**: Simplex, Branch & Bound, Gráfico, Transporte, Asignación, Monte Carlo
- **Análisis de sensibilidad**: precios sombra, rangos de coeficientes, costos reducidos
- **Importación Excel/CSV**: detección automática de tipo de datos
- **Modo dual**: emprendedor (recomendaciones simples) y estudiante (traza paso a paso)
- **Voz**: entrada por voz offline + lectura de resultados
- **Temas**: oscuro y claro con diseño profesional
- **Semáforo de confianza**: indicador visual verde/amarillo/rojo

## Licencia

Proyecto académico — Universidad Peruana Unión, 2024.
