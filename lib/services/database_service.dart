import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:asistente_pl/models/lp_models.dart';

/// Servicio de base de datos local.
/// Usa SharedPreferences como almacenamiento ligero.
/// Para producción, migrar a Drift/SQLite con el esquema completo.
class DatabaseService {
  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ── Perfil de empresa ──────────────────────────────────────────
  Future<void> guardarPerfil(Map<String, dynamic> perfil) async {
    await _prefs.setString('perfil_empresa', jsonEncode(perfil));
  }

  Map<String, dynamic>? obtenerPerfil() {
    final s = _prefs.getString('perfil_empresa');
    if (s == null) return null;
    return jsonDecode(s) as Map<String, dynamic>;
  }

  // ── Modelos guardados ──────────────────────────────────────────
  Future<void> guardarModelo(ProblemaLP modelo) async {
    final lista = _obtenerModelos();
    // Reemplazar si ya existe con el mismo nombre
    lista.removeWhere((m) => m['nombre'] == modelo.nombre);
    lista.add(modelo.toJson());
    await _prefs.setString('modelos_lp', jsonEncode(lista));
  }

  List<ProblemaLP> listarModelos() {
    return _obtenerModelos()
        .map((j) => ProblemaLP.fromJson(j as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.creado.compareTo(a.creado));
  }

  Future<void> eliminarModelo(String nombre) async {
    final lista = _obtenerModelos();
    lista.removeWhere((m) => m['nombre'] == nombre);
    await _prefs.setString('modelos_lp', jsonEncode(lista));
  }

  List<dynamic> _obtenerModelos() {
    final s = _prefs.getString('modelos_lp');
    if (s == null) return [];
    return jsonDecode(s) as List<dynamic>;
  }

  // ── Historial de chat ──────────────────────────────────────────
  Future<void> guardarHistorialChat(List<Map<String, dynamic>> mensajes) async {
    await _prefs.setString('historial_chat', jsonEncode(mensajes));
  }

  List<Map<String, dynamic>> obtenerHistorialChat() {
    final s = _prefs.getString('historial_chat');
    if (s == null) return [];
    return (jsonDecode(s) as List).cast<Map<String, dynamic>>();
  }

  // ── Configuración ──────────────────────────────────────────────
  Future<void> guardarConfiguracion(String clave, dynamic valor) async {
    final config = obtenerConfiguracion();
    config[clave] = valor;
    await _prefs.setString('config_app', jsonEncode(config));
  }

  Map<String, dynamic> obtenerConfiguracion() {
    final s = _prefs.getString('config_app');
    if (s == null) return {};
    return jsonDecode(s) as Map<String, dynamic>;
  }

  // ── Modo (mi negocio / estudiante) ─────────────────────────────
  Future<void> setModo(String modo) async {
    await _prefs.setString('modo_app', modo);
  }

  String getModo() => _prefs.getString('modo_app') ?? 'negocio';

  // ── Limpiar todo ───────────────────────────────────────────────
  Future<void> limpiarTodo() async {
    await _prefs.clear();
  }
}
