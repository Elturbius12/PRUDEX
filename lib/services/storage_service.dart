import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/perfil_empresa.dart';
import '../models/producto.dart';
import '../models/origen_destino.dart';
import '../data/ejemplos.dart' as ejemplos;

/// Persiste el perfil de empresa y los datos de sesión (productos, orígenes,
/// destinos, costos) en el almacenamiento local del dispositivo, para que
/// el asistente los recuerde entre usos sin depender de un backend
/// (ver sección 9.4 del documento: "Módulo de perfil de empresa").
class StorageService {
  static const _kPerfil = 'perfil_empresa';
  static const _kProductos = 'produccion_productos';
  static const _kHilo = 'produccion_hilo_disponible';
  static const _kTiempo = 'produccion_tiempo_disponible';
  static const _kOrigenes = 'rutas_origenes';
  static const _kDestinos = 'rutas_destinos';
  static const _kCostos = 'rutas_costos';

  Future<PerfilEmpresa> cargarPerfil() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_kPerfil);
    if (raw == null) return PerfilEmpresa();
    try {
      return PerfilEmpresa.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return PerfilEmpresa();
    }
  }

  Future<void> guardarPerfil(PerfilEmpresa perfil) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kPerfil, jsonEncode(perfil.toJson()));
  }

  Future<List<Producto>> cargarProductos() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_kProductos);
    if (raw == null) return _productosEjemplo();
    try {
      final lista = jsonDecode(raw) as List<dynamic>;
      return lista.map((e) => Producto.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return _productosEjemplo();
    }
  }

  Future<void> guardarProductos(List<Producto> productos) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kProductos, jsonEncode(productos.map((p) => p.toJson()).toList()));
  }

  Future<double?> cargarHiloDisponible() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getDouble(_kHilo);
  }

  Future<void> guardarHiloDisponible(double valor) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setDouble(_kHilo, valor);
  }

  Future<double?> cargarTiempoDisponible() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getDouble(_kTiempo);
  }

  Future<void> guardarTiempoDisponible(double valor) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setDouble(_kTiempo, valor);
  }

  Future<List<Origen>> cargarOrigenes() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_kOrigenes);
    if (raw == null) return _origenesEjemplo();
    try {
      final lista = jsonDecode(raw) as List<dynamic>;
      return lista.map((e) => Origen.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return _origenesEjemplo();
    }
  }

  Future<void> guardarOrigenes(List<Origen> origenes) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kOrigenes, jsonEncode(origenes.map((o) => o.toJson()).toList()));
  }

  Future<List<Destino>> cargarDestinos() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_kDestinos);
    if (raw == null) return _destinosEjemplo();
    try {
      final lista = jsonDecode(raw) as List<dynamic>;
      return lista.map((e) => Destino.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return _destinosEjemplo();
    }
  }

  Future<void> guardarDestinos(List<Destino> destinos) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kDestinos, jsonEncode(destinos.map((d) => d.toJson()).toList()));
  }

  Future<List<List<double>>> cargarCostos() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_kCostos);
    if (raw == null) return _costosEjemplo();
    try {
      final lista = jsonDecode(raw) as List<dynamic>;
      return lista
          .map((fila) => (fila as List<dynamic>).map((v) => (v as num).toDouble()).toList())
          .toList();
    } catch (_) {
      return _costosEjemplo();
    }
  }

  Future<void> guardarCostos(List<List<double>> costos) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kCostos, jsonEncode(costos));
  }

  // ---- Datos de ejemplo (delegados a data/ejemplos.dart) ----
  List<Producto> _productosEjemplo() => ejemplos.productosEjemplo();
  List<Origen> _origenesEjemplo() => ejemplos.origenesEjemplo();
  List<Destino> _destinosEjemplo() => ejemplos.destinosEjemplo();
  List<List<double>> _costosEjemplo() => ejemplos.costosEjemplo();
}
