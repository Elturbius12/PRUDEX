import 'package:flutter/material.dart';
import 'package:asistente_pl/models/lp_models.dart';
import 'package:asistente_pl/services/database_service.dart';
import 'package:asistente_pl/services/gemini_service.dart';
import 'package:asistente_pl/services/voice_service.dart';
import 'package:asistente_pl/services/supabase_service.dart';
import 'package:asistente_pl/services/excel_service.dart';
import 'package:asistente_pl/core/solver_engine.dart';
import 'package:asistente_pl/core/explicacion_service.dart';
import 'package:uuid/uuid.dart';

class AppState extends ChangeNotifier {
  final DatabaseService db;
  final GeminiService gemini = GeminiService();
  final VoiceService voice = VoiceService();
  final SupabaseService supabase = SupabaseService();
  final ExcelService excel = ExcelService();
  final SolverEngine solver = SolverEngine();
  final ExplicacionService explicaciones = ExplicacionService();
  final _uuid = const Uuid();

  // ── Estado base ───────────────────────────────────────────────
  String _modo = 'negocio'; // 'negocio' o 'estudiante'
  int _tabActual = 0;
  int? _pestanaSolicitada;
  ProblemaLP? _modeloActual;
  ResultadoLP? _resultadoActual;
  List<MensajeChat> _mensajesChat = [];
  List<ProblemaLP> _modelosGuardados = [];
  bool _resolviendo = false;
  Map<String, dynamic>? _perfilEmpresa;
  String _nivelExplicacion = 'simple'; // 'simple' | 'detallado' | 'tecnico'

  // ── Módulo de producción ──────────────────────────────────────
  double _hiloDisponible = 100.0;
  double _tiempoDisponible = 80.0;
  List<Map<String, dynamic>> _productos = [];
  ResultadoLP? _resultadoProduccion;

  // ── Módulo de rutas / transporte ──────────────────────────────
  List<Map<String, dynamic>> _origenes = [];
  List<Map<String, dynamic>> _destinos = [];
  ResultadoLP? _resultadoRutas;

  // ── Getters base ──────────────────────────────────────────────
  String get modo => _modo;
  int get tabActual => _tabActual;
  int get pestanaActual => _tabActual;
  int? get pestanaSolicitada => _pestanaSolicitada;
  ProblemaLP? get modeloActual => _modeloActual;
  ResultadoLP? get resultadoActual => _resultadoActual;
  List<MensajeChat> get mensajesChat => _mensajesChat;
  List<ProblemaLP> get modelosGuardados => _modelosGuardados;
  bool get resolviendo => _resolviendo;
  bool get cargando => _resolviendo;
  Map<String, dynamic>? get perfilEmpresa => _perfilEmpresa;
  bool get esEstudiante => _modo == 'estudiante';
  String get nivelExplicacion => _nivelExplicacion;

  /// Perfil no nulable — devuelve PerfilEmpresa vacío si aún no se configuró.
  PerfilEmpresa get perfil {
    if (_perfilEmpresa == null) return const PerfilEmpresa();
    return PerfilEmpresa.fromJson(_perfilEmpresa!);
  }

  // ── Getters módulo producción ─────────────────────────────────
  double get hiloDisponible => _hiloDisponible;
  double get tiempoDisponible => _tiempoDisponible;
  List<Map<String, dynamic>> get productos => _productos;
  ResultadoLP? get resultadoProduccion => _resultadoProduccion;

  // ── Getters módulo rutas ──────────────────────────────────────
  List<Map<String, dynamic>> get origenes => _origenes;
  List<Map<String, dynamic>> get destinos => _destinos;
  ResultadoLP? get resultadoRutas => _resultadoRutas;

  // ── Constructor ───────────────────────────────────────────────
  AppState({required this.db}) {
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    _modo = db.getModo();
    _modelosGuardados = db.listarModelos();
    _perfilEmpresa = db.obtenerPerfil();
    await voice.init();
    notifyListeners();
  }

  // ── Navegación ────────────────────────────────────────────────
  void setTab(int idx) {
    _tabActual = idx;
    notifyListeners();
  }

  void setModo(String modo) {
    _modo = modo;
    db.setModo(modo);
    notifyListeners();
  }

  /// Solicita cambiar de pestaña; la UI lo consume con [confirmarNavegacionConsumida].
  void pedirNavegacion(int tab) {
    _pestanaSolicitada = tab;
    notifyListeners();
  }

  /// Marca la navegación solicitada como consumida.
  void confirmarNavegacionConsumida() {
    _pestanaSolicitada = null;
    // Sin notifyListeners — evita rebuild innecesario.
  }

  /// Cambia el nivel de detalle de las explicaciones ('simple', 'detallado', 'tecnico').
  void cambiarNivelExplicacion(String nivel) {
    _nivelExplicacion = nivel;
    notifyListeners();
  }

  // ── Modelo ────────────────────────────────────────────────────
  void setModelo(ProblemaLP modelo) {
    _modeloActual = modelo;
    _resultadoActual = null;
    notifyListeners();
  }

  void limpiarModelo() {
    _modeloActual = null;
    _resultadoActual = null;
    notifyListeners();
  }

  // ── Resolver modelo principal ─────────────────────────────────
  Future<void> resolverModelo() async {
    if (_modeloActual == null) return;

    _resolviendo = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 50)); // yield al UI
    _resultadoActual = solver.resolver(_modeloActual!);

    _resolviendo = false;
    notifyListeners();

    if (_resultadoActual != null) {
      final rec = explicaciones.generarRecomendacion(_modeloActual!, _resultadoActual!);
      agregarMensajeBot(
        rec.explicacion,
        tipo: TipoMensaje.resultado,
        datos: {
          'decision': rec.decision,
          'impacto': rec.impacto,
          'confianza': rec.confianza,
        },
      );
    }
  }

  // ── Chat ──────────────────────────────────────────────────────
  Future<void> enviarMensaje(String texto) async {
    _mensajesChat.add(MensajeChat(
      id: _uuid.v4(),
      texto: texto,
      esUsuario: true,
    ));

    final loadingId = _uuid.v4();
    _mensajesChat.add(MensajeChat(
      id: loadingId,
      texto: '',
      esUsuario: false,
      tipo: TipoMensaje.cargando,
    ));
    notifyListeners();

    final contexto = <String, dynamic>{
      'negocio': _perfilEmpresa?['tipo'] ?? '',
      'datos': _modeloActual?.toJson(),
    };
    final interpretacion = await gemini.interpretar(texto, contexto: contexto);

    _mensajesChat.removeWhere((m) => m.id == loadingId);

    switch (interpretacion.intencion) {
      case 'crear_modelo':
      case 'modificar_modelo':
        if (interpretacion.modelo != null) {
          _modeloActual = interpretacion.modelo;
        }
        agregarMensajeBot(interpretacion.respuesta);
        if (interpretacion.preguntaSiguiente != null) {
          agregarMensajeBot(interpretacion.preguntaSiguiente!);
        }
        break;

      case 'resolver':
        if (_modeloActual != null) {
          agregarMensajeBot('Resolviendo tu modelo...');
          await resolverModelo();
        } else {
          agregarMensajeBot(
            'Aún no tengo un modelo completo. Cuéntame qué quieres optimizar.',
          );
        }
        break;

      case 'analizar_sensibilidad':
        if (_resultadoActual?.sensibilidad != null) {
          agregarMensajeBot(_formatearSensibilidad(_resultadoActual!.sensibilidad!));
        } else {
          agregarMensajeBot(
              'Primero necesito resolver un modelo para hacer el análisis.');
        }
        break;

      case 'simular':
        if (_modeloActual != null) {
          agregarMensajeBot('Ejecutando simulación Monte Carlo (500 escenarios)...');
          final mc = solver.simularMonteCarlo(_modeloActual!);
          agregarMensajeBot(
            'Resultado de la simulación:\n'
            '\u2022 Valor esperado: ${mc.mediaObjetivo.toStringAsFixed(2)}\n'
            '\u2022 Rango probable (90%): ${mc.percentil5.toStringAsFixed(2)} a ${mc.percentil95.toStringAsFixed(2)}\n'
            '\u2022 Probabilidad de ser factible: ${(mc.probabilidadFactible * 100).toStringAsFixed(0)}%',
            tipo: TipoMensaje.resultado,
          );
        } else {
          agregarMensajeBot('Necesito un modelo para simular.');
        }
        break;

      default:
        agregarMensajeBot(interpretacion.respuesta);
        if (interpretacion.preguntaSiguiente != null) {
          agregarMensajeBot(interpretacion.preguntaSiguiente!);
        }
    }

    if (interpretacion.datosQueNecesito.isNotEmpty) {
      _mensajesChat.add(MensajeChat(
        id: _uuid.v4(),
        texto: '',
        esUsuario: false,
        tipo: TipoMensaje.sugerencia,
        datos: {'sugerencias': interpretacion.datosQueNecesito},
      ));
      notifyListeners();
    }
  }

  void agregarMensajeBot(
    String texto, {
    TipoMensaje tipo = TipoMensaje.texto,
    Map<String, dynamic>? datos,
  }) {
    _mensajesChat.add(MensajeChat(
      id: _uuid.v4(),
      texto: texto,
      esUsuario: false,
      tipo: tipo,
      datos: datos,
    ));
    notifyListeners();
  }

  // ── Perfil ────────────────────────────────────────────────────
  Future<void> guardarPerfil(dynamic perfilData) async {
    if (perfilData is Map<String, dynamic>) {
      _perfilEmpresa = perfilData;
      await db.guardarPerfil(perfilData);
    } else if (perfilData is PerfilEmpresa) {
      final json = perfilData.toJson();
      _perfilEmpresa = json;
      await db.guardarPerfil(json);
    }
    notifyListeners();
  }

  // ── Modelos guardados ─────────────────────────────────────────
  Future<void> guardarModeloActual() async {
    if (_modeloActual == null) return;
    await db.guardarModelo(_modeloActual!);
    _modelosGuardados = db.listarModelos();
    notifyListeners();
  }

  Future<void> cargarModelo(ProblemaLP modelo) async {
    _modeloActual = modelo;
    _resultadoActual = null;
    notifyListeners();
  }

  Future<void> eliminarModelo(String nombre) async {
    await db.eliminarModelo(nombre);
    _modelosGuardados = db.listarModelos();
    notifyListeners();
  }

  // ── Módulo de producción ──────────────────────────────────────

  void setHiloDisponible(double valor) {
    _hiloDisponible = valor;
    notifyListeners();
  }

  void setTiempoDisponible(double valor) {
    _tiempoDisponible = valor;
    notifyListeners();
  }

  void agregarProducto() {
    _productos.add({
      'nombre': 'Producto ${_productos.length + 1}',
      'gananciaPorUnidad': 0.0,
      'hiloPorUnidad': 0.0,
      'tiempoPorUnidad': 0.0,
    });
    notifyListeners();
  }

  void actualizarProductoCampo(int index, String campo, dynamic valor) {
    if (index < 0 || index >= _productos.length) return;
    _productos[index][campo] = valor;
    notifyListeners();
  }

  void quitarProducto(int index) {
    if (index < 0 || index >= _productos.length) return;
    _productos.removeAt(index);
    notifyListeners();
  }

  Future<void> resolverProduccion() async {
    if (_productos.isEmpty) return;

    _resolviendo = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 50));

    final variables = _productos
        .map((p) => VariableLP(
              nombre: p['nombre'] as String? ?? 'Producto',
              coeficienteObjetivo:
                  (p['gananciaPorUnidad'] as num?)?.toDouble() ?? 0.0,
            ))
        .toList();

    final restricciones = [
      RestriccionLP(
        nombre: 'Hilo disponible',
        coeficientes: _productos
            .map((p) => (p['hiloPorUnidad'] as num?)?.toDouble() ?? 0.0)
            .toList(),
        tipo: TipoRestriccion.menorIgual,
        rhs: _hiloDisponible,
      ),
      RestriccionLP(
        nombre: 'Tiempo disponible',
        coeficientes: _productos
            .map((p) => (p['tiempoPorUnidad'] as num?)?.toDouble() ?? 0.0)
            .toList(),
        tipo: TipoRestriccion.menorIgual,
        rhs: _tiempoDisponible,
      ),
    ];

    final problema = ProblemaLP(
      nombre: 'Producción óptima',
      objetivo: TipoObjetivo.maximizar,
      variables: variables,
      restricciones: restricciones,
    );

    _resultadoProduccion = solver.resolver(problema);
    _resolviendo = false;
    notifyListeners();
  }

  void cargarEjemploProduccion() {
    _hiloDisponible = 100.0;
    _tiempoDisponible = 80.0;
    _productos = [
      {
        'nombre': 'Chompa',
        'gananciaPorUnidad': 25.0,
        'hiloPorUnidad': 3.0,
        'tiempoPorUnidad': 2.0,
      },
      {
        'nombre': 'Chaleco',
        'gananciaPorUnidad': 18.0,
        'hiloPorUnidad': 2.0,
        'tiempoPorUnidad': 1.5,
      },
    ];
    _resultadoProduccion = null;
    notifyListeners();
  }

  String resumenHabladoProduccion() {
    if (_resultadoProduccion == null) return 'No hay resultado de producción.';
    if (_resultadoProduccion!.estado != EstadoSolucion.optimo) {
      return 'No se encontró solución factible para la producción.';
    }
    final z = _resultadoProduccion!.valorOptimo ?? 0;
    final vals = _resultadoProduccion!.valoresVariables;
    final buf = StringBuffer('La ganancia máxima es ${z.toStringAsFixed(2)} soles. ');
    for (final e in vals.entries) {
      if (e.value > 0.01) {
        buf.write('Produce ${e.value.toStringAsFixed(0)} unidades de ${e.key}. ');
      }
    }
    return buf.toString();
  }

  // ── Módulo de rutas / transporte ──────────────────────────────

  void agregarOrigen() {
    final costos = List<double>.filled(_destinos.length, 0.0);
    _origenes.add({
      'nombre': 'Origen ${_origenes.length + 1}',
      'oferta': 0.0,
      'costos': costos,
    });
    notifyListeners();
  }

  void quitarOrigen(int index) {
    if (index < 0 || index >= _origenes.length) return;
    _origenes.removeAt(index);
    notifyListeners();
  }

  void actualizarOrigenCampo(int index, String campo, dynamic valor) {
    if (index < 0 || index >= _origenes.length) return;
    _origenes[index][campo] = valor;
    notifyListeners();
  }

  void agregarDestino() {
    _destinos.add({
      'nombre': 'Destino ${_destinos.length + 1}',
      'demanda': 0.0,
    });
    // Agregar columna de costo (0) a cada origen existente
    for (final o in _origenes) {
      final costos = List<double>.from(o['costos'] as List? ?? []);
      costos.add(0.0);
      o['costos'] = costos;
    }
    notifyListeners();
  }

  void quitarDestino(int index) {
    if (index < 0 || index >= _destinos.length) return;
    _destinos.removeAt(index);
    for (final o in _origenes) {
      final costos = List<double>.from(o['costos'] as List? ?? []);
      if (index < costos.length) costos.removeAt(index);
      o['costos'] = costos;
    }
    notifyListeners();
  }

  void actualizarDestinoCampo(int index, String campo, dynamic valor) {
    if (index < 0 || index >= _destinos.length) return;
    _destinos[index][campo] = valor;
    notifyListeners();
  }

  void actualizarCosto(int origenIdx, int destinoIdx, double valor) {
    if (origenIdx < 0 || origenIdx >= _origenes.length) return;
    final costos = List<double>.from(_origenes[origenIdx]['costos'] as List? ?? []);
    if (destinoIdx < 0 || destinoIdx >= costos.length) return;
    costos[destinoIdx] = valor;
    _origenes[origenIdx]['costos'] = costos;
    notifyListeners();
  }

  Future<void> resolverRutas() async {
    if (_origenes.isEmpty || _destinos.isEmpty) return;

    _resolviendo = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 50));

    final oferta =
        _origenes.map((o) => (o['oferta'] as num?)?.toDouble() ?? 0.0).toList();
    final demanda =
        _destinos.map((d) => (d['demanda'] as num?)?.toDouble() ?? 0.0).toList();
    final matrizCostos = _origenes.map((o) {
      final c = o['costos'] as List? ?? [];
      return c.map((v) => (v as num?)?.toDouble() ?? 0.0).toList();
    }).toList();

    final problema = ProblemaTransporte(
      origenes: _origenes.map((o) => o['nombre'] as String? ?? '').toList(),
      destinos: _destinos.map((d) => d['nombre'] as String? ?? '').toList(),
      oferta: oferta,
      demanda: demanda,
      costos: matrizCostos,
    );

    final resultadoTransporte = solver.resolverTransporte(problema);

    _resultadoRutas = ResultadoLP(
      estado: EstadoSolucion.optimo,
      valorOptimo: resultadoTransporte.costoTotal,
      valoresVariables: const {},
      explicacionSimple:
          'Costo mínimo de transporte: ${resultadoTransporte.costoTotal.toStringAsFixed(2)}',
      explicacionDetallada:
          'Se usó el método: ${resultadoTransporte.metodoUsado}.\n'
          '${resultadoTransporte.pasos.join('\n')}',
    );

    _resolviendo = false;
    notifyListeners();
  }

  String resumenHabladoRutas() {
    if (_resultadoRutas == null) return 'No hay resultado de rutas disponible.';
    final costo = _resultadoRutas!.valorOptimo ?? 0;
    return 'El costo mínimo de transporte es ${costo.toStringAsFixed(2)} soles, '
        'optimizando ${_origenes.length} origen(es) y ${_destinos.length} destino(s).';
  }

  // ── Utilidades privadas ───────────────────────────────────────

  String _formatearSensibilidad(AnalisisSensibilidad s) {
    final buf = StringBuffer('Análisis de sensibilidad:\n\n');

    buf.writeln('Coeficientes de la función objetivo:');
    for (final r in s.rangosObjetivo) {
      buf.writeln(
          '  ${r.variable}: puede variar de ${r.limiteInferior.toStringAsFixed(2)} '
          'a ${r.limiteSuperior.toStringAsFixed(2)} sin cambiar la solución');
    }

    buf.writeln('\nValores del lado derecho (recursos):');
    for (final r in s.rangosRHS) {
      buf.writeln(
          '  ${r.restriccion}: rango ${r.limiteInferior.toStringAsFixed(2)} '
          'a ${r.limiteSuperior.toStringAsFixed(2)}, '
          'precio sombra = ${r.precioSombra.toStringAsFixed(4)}');
    }

    return buf.toString();
  }
}