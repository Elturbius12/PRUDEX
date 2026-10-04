import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:asistente_pl/config.dart';

/// Servicio de Supabase para autenticación y banco de conocimiento.
class SupabaseService {
  bool _inicializado = false;
  String? _accessToken;
  String? _userId;

  bool get disponible =>
      AppConfig.supabaseUrl != 'TU_SUPABASE_URL' &&
      AppConfig.supabaseAnonKey != 'TU_SUPABASE_ANON_KEY';
  bool get autenticado => _accessToken != null;
  String? get userId => _userId;

  /// Inicializa la conexión con Supabase.
  Future<bool> init() async {
    if (!disponible) return false;
    _inicializado = true;
    return true;
  }

  /// Registrar nuevo usuario.
  Future<({bool ok, String mensaje})> registrar(String email, String password) async {
    if (!disponible) return (ok: false, mensaje: 'Supabase no configurado');

    try {
      final resp = await http.post(
        Uri.parse('${AppConfig.supabaseUrl}/auth/v1/signup'),
        headers: {
          'Content-Type': 'application/json',
          'apikey': AppConfig.supabaseAnonKey,
        },
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        final data = jsonDecode(resp.body);
        _accessToken = data['access_token'] as String?;
        _userId = data['user']?['id'] as String?;
        return (ok: true, mensaje: 'Cuenta creada exitosamente');
      }

      final error = jsonDecode(resp.body);
      return (ok: false, mensaje: error['msg'] as String? ?? 'Error al registrar');
    } catch (e) {
      return (ok: false, mensaje: 'Error de conexión: $e');
    }
  }

  /// Iniciar sesión.
  Future<({bool ok, String mensaje})> login(String email, String password) async {
    if (!disponible) return (ok: false, mensaje: 'Supabase no configurado');

    try {
      final resp = await http.post(
        Uri.parse('${AppConfig.supabaseUrl}/auth/v1/token?grant_type=password'),
        headers: {
          'Content-Type': 'application/json',
          'apikey': AppConfig.supabaseAnonKey,
        },
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        _accessToken = data['access_token'] as String?;
        _userId = data['user']?['id'] as String?;
        return (ok: true, mensaje: 'Sesión iniciada');
      }

      return (ok: false, mensaje: 'Credenciales incorrectas');
    } catch (e) {
      return (ok: false, mensaje: 'Error de conexión');
    }
  }

  /// Cerrar sesión.
  void logout() {
    _accessToken = null;
    _userId = null;
  }

  /// Headers autenticados.
  Map<String, String> get _authHeaders => {
        'Content-Type': 'application/json',
        'apikey': AppConfig.supabaseAnonKey,
        if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
      };

  // ── Banco de conocimiento ──────────────────────────────────────

  /// Guardar dato en el banco de conocimiento.
  Future<bool> guardarDatoMercado(Map<String, dynamic> dato) async {
    if (!disponible || !autenticado) return false;

    try {
      final resp = await http.post(
        Uri.parse('${AppConfig.supabaseUrl}/rest/v1/datos_mercado'),
        headers: _authHeaders,
        body: jsonEncode({...dato, 'user_id': _userId}),
      );
      return resp.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  /// Consultar datos del mercado.
  Future<List<Map<String, dynamic>>> consultarDatosMercado({
    String? tipo,
    String? busqueda,
  }) async {
    if (!disponible) return [];

    try {
      var url = '${AppConfig.supabaseUrl}/rest/v1/datos_mercado?select=*';
      if (tipo != null) url += '&tipo=eq.$tipo';
      if (busqueda != null) url += '&descripcion=ilike.*$busqueda*';
      url += '&order=created_at.desc&limit=50';

      final resp = await http.get(
        Uri.parse(url),
        headers: _authHeaders,
      );

      if (resp.statusCode == 200) {
        return (jsonDecode(resp.body) as List).cast<Map<String, dynamic>>();
      }
    } catch (_) {}
    return [];
  }

  /// Subir archivo al storage de Supabase.
  Future<String?> subirArchivo(String bucket, String path, List<int> bytes,
      {String? contentType}) async {
    if (!disponible || !autenticado) return null;

    try {
      final resp = await http.post(
        Uri.parse('${AppConfig.supabaseUrl}/storage/v1/object/$bucket/$path'),
        headers: {
          ..._authHeaders,
          'Content-Type': contentType ?? 'application/octet-stream',
        },
        body: bytes,
      );

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        return '${AppConfig.supabaseUrl}/storage/v1/object/public/$bucket/$path';
      }
    } catch (_) {}
    return null;
  }
}
