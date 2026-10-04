import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:asistente_pl/config.dart';
import 'package:asistente_pl/models/lp_models.dart';

/// Servicio de Gemini para NLU y extracción de datos.
class GeminiService {
  static const _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models';
  bool _disponible = false;

  bool get disponible => _disponible && AppConfig.geminiApiKey != 'TU_GEMINI_API_KEY';

  GeminiService() {
    _disponible = AppConfig.geminiApiKey != 'TU_GEMINI_API_KEY';
  }

  /// Interpreta la intención del usuario y extrae datos del modelo LP.
  Future<InterpretacionNLU> interpretar(String textoUsuario,
      {Map<String, dynamic>? contexto}) async {
    if (!disponible) {
      return _interpretarLocal(textoUsuario);
    }

    final prompt = '''Eres un asistente de programación lineal para emprendedores de Juliaca, Perú.
El usuario quiere resolver un problema de optimización para su negocio.

Contexto del negocio: ${contexto?['negocio'] ?? 'No especificado'}
Datos previos: ${contexto?['datos'] ?? 'Ninguno'}

Mensaje del usuario: "$textoUsuario"

Responde en JSON con esta estructura exacta:
{
  "intencion": "crear_modelo" | "modificar_modelo" | "resolver" | "explicar" | "analizar_sensibilidad" | "simular" | "pregunta_general" | "necesito_mas_datos",
  "datosExtraidos": {
    "objetivo": "maximizar" | "minimizar" | null,
    "variables": [{"nombre": "...", "coeficiente": 0.0}] | null,
    "restricciones": [{"nombre": "...", "coeficientes": [0.0], "tipo": "<=" | ">=" | "=", "rhs": 0.0}] | null,
    "tipoNegocio": "..." | null
  },
  "datosQueNecesito": ["lista de datos que faltan para construir el modelo"],
  "respuestaUsuario": "Respuesta amigable en español para el emprendedor",
  "preguntaSiguiente": "Pregunta para obtener los datos faltantes"
}''';

    try {
      final body = jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': prompt}
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.3,
          'maxOutputTokens': 2048,
          'responseMimeType': 'application/json',
        },
      });

      final resp = await http.post(
        Uri.parse('$_baseUrl/${AppConfig.geminiModel}:generateContent?key=${AppConfig.geminiApiKey}'),
        headers: {'Content-Type': 'application/json'},
        body: body,
      ).timeout(const Duration(seconds: 15));

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'] as String?;
        if (text != null) {
          return _parsearRespuesta(text);
        }
      }
    } catch (e) {
      // Fallback a interpretación local
    }

    return _interpretarLocal(textoUsuario);
  }

  /// Extrae datos de un documento para el banco de conocimiento.
  Future<Map<String, dynamic>> extraerDatosDocumento(String contenido) async {
    if (!disponible) {
      return {'error': 'Gemini no configurado'};
    }

    final prompt = '''Analiza este documento y extrae datos relevantes para decisiones de negocios en Juliaca, Perú.
Busca: datos de población, precios, demanda, tendencias, costos, estacionalidad.

Documento:
$contenido

Responde en JSON:
{
  "datos": [
    {"tipo": "poblacion|precio|demanda|costo|tendencia|estacionalidad", "descripcion": "...", "valor": 0.0, "unidad": "...", "fuente": "...", "fecha": "..."}
  ],
  "resumen": "Resumen en una oración"
}''';

    try {
      final resp = await http.post(
        Uri.parse('$_baseUrl/${AppConfig.geminiModel}:generateContent?key=${AppConfig.geminiApiKey}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.2,
            'maxOutputTokens': 2048,
            'responseMimeType': 'application/json',
          },
        }),
      ).timeout(const Duration(seconds: 20));

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'] as String?;
        if (text != null) {
          return jsonDecode(text) as Map<String, dynamic>;
        }
      }
    } catch (_) {}

    return {'datos': [], 'resumen': 'No se pudieron extraer datos.'};
  }

  InterpretacionNLU _parsearRespuesta(String json) {
    try {
      final data = jsonDecode(json) as Map<String, dynamic>;
      final intencion = data['intencion'] as String? ?? 'pregunta_general';
      final respuesta = data['respuestaUsuario'] as String? ?? '';
      final pregunta = data['preguntaSiguiente'] as String?;
      final datosQueNecesito =
          (data['datosQueNecesito'] as List?)?.cast<String>() ?? [];

      ProblemaLP? modelo;
      final datosExt = data['datosExtraidos'] as Map<String, dynamic>?;
      if (datosExt != null && datosExt['variables'] != null) {
        final vars = (datosExt['variables'] as List)
            .map((v) => VariableLP(
                  nombre: v['nombre'] as String,
                  coeficienteObjetivo: (v['coeficiente'] as num).toDouble(),
                ))
            .toList();

        List<RestriccionLP>? restricciones;
        if (datosExt['restricciones'] != null) {
          restricciones = (datosExt['restricciones'] as List).map((r) {
            final tipoStr = r['tipo'] as String? ?? '<=';
            TipoRestriccion tipo;
            switch (tipoStr) {
              case '>=':
                tipo = TipoRestriccion.mayorIgual;
                break;
              case '=':
                tipo = TipoRestriccion.igual;
                break;
              default:
                tipo = TipoRestriccion.menorIgual;
            }
            return RestriccionLP(
              nombre: r['nombre'] as String,
              coeficientes: (r['coeficientes'] as List)
                  .map((c) => (c as num).toDouble())
                  .toList(),
              tipo: tipo,
              rhs: (r['rhs'] as num).toDouble(),
            );
          }).toList();
        }

        final objStr = datosExt['objetivo'] as String?;
        modelo = ProblemaLP(
          nombre: 'Modelo del usuario',
          objetivo: objStr == 'minimizar'
              ? TipoObjetivo.minimizar
              : TipoObjetivo.maximizar,
          variables: vars,
          restricciones: restricciones ?? [],
        );
      }

      return InterpretacionNLU(
        intencion: intencion,
        modelo: modelo,
        respuesta: respuesta,
        preguntaSiguiente: pregunta,
        datosQueNecesito: datosQueNecesito,
      );
    } catch (_) {
      return InterpretacionNLU(
        intencion: 'pregunta_general',
        respuesta: 'No pude interpretar completamente tu solicitud. ¿Podrías reformularla?',
      );
    }
  }

  /// Interpretación local básica sin Gemini.
  InterpretacionNLU _interpretarLocal(String texto) {
    final lower = texto.toLowerCase();

    if (lower.contains('maximizar') || lower.contains('ganancia') ||
        lower.contains('más dinero') || lower.contains('producir')) {
      return InterpretacionNLU(
        intencion: 'crear_modelo',
        respuesta: 'Entiendo que quieres maximizar tus ganancias. '
            'Necesito algunos datos para construir tu modelo.',
        preguntaSiguiente: '¿Qué productos o servicios ofreces y cuánto ganas con cada uno?',
        datosQueNecesito: ['productos', 'ganancia por producto', 'recursos disponibles'],
      );
    }

    if (lower.contains('minimizar') || lower.contains('costo') ||
        lower.contains('gasto') || lower.contains('barato')) {
      return InterpretacionNLU(
        intencion: 'crear_modelo',
        respuesta: 'Entiendo que quieres minimizar costos. '
            'Vamos a construir un modelo para optimizar tus gastos.',
        preguntaSiguiente: '¿Qué operaciones o insumos generan costos en tu negocio?',
        datosQueNecesito: ['operaciones', 'costos', 'requisitos mínimos'],
      );
    }

    if (lower.contains('transporte') || lower.contains('enviar') ||
        lower.contains('distribuir')) {
      return InterpretacionNLU(
        intencion: 'crear_modelo',
        respuesta: 'Parece que necesitas optimizar distribución o transporte.',
        preguntaSiguiente: '¿Desde dónde envías y hacia dónde? ¿Cuánto puede enviar cada origen?',
        datosQueNecesito: ['orígenes', 'destinos', 'capacidades', 'costos de envío'],
      );
    }

    if (lower.contains('resolver') || lower.contains('calcular') ||
        lower.contains('solución')) {
      return InterpretacionNLU(
        intencion: 'resolver',
        respuesta: 'Voy a resolver tu modelo.',
      );
    }

    return InterpretacionNLU(
      intencion: 'necesito_mas_datos',
      respuesta: 'Cuéntame más sobre tu negocio y qué decisión necesitas tomar.',
      preguntaSiguiente: '¿Qué tipo de negocio tienes y qué quieres optimizar?',
      datosQueNecesito: ['tipo de negocio', 'objetivo', 'recursos'],
    );
  }
}

/// Resultado de la interpretación NLU.
class InterpretacionNLU {
  final String intencion;
  final ProblemaLP? modelo;
  final String respuesta;
  final String? preguntaSiguiente;
  final List<String> datosQueNecesito;

  InterpretacionNLU({
    required this.intencion,
    this.modelo,
    required this.respuesta,
    this.preguntaSiguiente,
    this.datosQueNecesito = const [],
  });
}
