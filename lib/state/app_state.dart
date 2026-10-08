import 'package:flutter/material.dart';
import 'package:asistente_pl/models/lp_models.dart';
import 'package:asistente_pl/models/producto.dart';
import 'package:asistente_pl/models/origen_destino.dart';
import 'package:asistente_pl/models/perfil_empresa.dart';
import 'package:asistente_pl/models/mensaje_chat.dart' as voz;
import 'package:asistente_pl/data/ejemplos.dart' as ejemplos;
import 'package:asistente_pl/services/database_service.dart';
import 'package:asistente_pl/services/gemini_service.dart';
import 'package:asistente_pl/services/voice_service.dart';
import 'package:asistente_pl/services/supabase_service.dart';
import 'package:asistente_pl/services/excel_service.dart';
import 'package:asistente_pl/services/storage_service.dart';
import 'package:asistente_pl/services/nlu_service.dart';
import 'package:asistente_pl/core/solver_engine.dart';
import 'package:asistente_pl/core/explicacion_service.dart';
import 'package:asistente_pl/core/lp_solver.dart';
import 'package:uuid/uuid.dart';

class AppState extends ChangeNotifier {
  final DatabaseService db;
  final GeminiService gemini = GeminiService();
  final VoiceService voice = VoiceService();
  final SupabaseService supabase = SupabaseService();
  final ExcelService excel = ExcelService();
  final SolverEngine solver = SolverEngine();
  final ExplicacionService explicaciones = ExplicacionService();
  final StorageService storage = StorageService();
  final _uuid = const Uuid();

  // ── Estado base (flujo de chat original) ────────────────────────
  String _modo = 'negocio'; // 'negocio' o 'estudiante'
  int _tabActual = 0;
  int? _pestanaSolicitada;
  ProblemaLP? _modeloActual;
  ResultadoLP? _resultadoActual;
  List<MensajeChat> _mensajesChat = [];
  List<ProblemaLP> _modelosGuardados = [];
  bool _resolviendo = false;
  Map<String, dynamic>? _perfilEmpresa;

  // ── Perfil de empresa (onboarding — perfil_screen.dart) ─────────
  PerfilEmpresa _perfil = PerfilEmpresa();

  // ── Nivel de explicación (asistente de voz) ─────────────────────
  voz.NivelExplicacion _nivelExplicacion = voz.NivelExplicacion.ejecutivo;

  // ── Módulo de producción ──────────────────────────────────────
  double _hiloDisponible = 100.0;
  double _tiempoDisponible = 80.0;
  List<Producto> _productos = [];
  ResultadoLP? _resultadoProduccion;

  // ── Módulo de rutas / transporte ──────────────────────────────
  List<Origen> _origenes = [];
  List<Destino> _destinos = [];
  List<List<double>> _costos = [];
  ResultadoLP? _resultadoRutas;
  String? _notaBalanceRutas;

  // ── Asistente de voz (panel_asistente.dart) ─────────────────────
  final List<voz.MensajeChat> _historial = [];
  String _transcripcionParcial = '';
  bool _vozActiva = true;

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
  voz.NivelExplicacion get nivelExplicacion => _nivelExplicacion;

  /// Perfil (onboarding) no nulable — usado por perfil_screen.dart.
  PerfilEmpresa get perfil => _perfil;

  // ── Getters módulo producción ─────────────────────────────────
  double get hiloDisponible => _hiloDisponible;
  double get tiempoDisponible => _tiempoDisponible;
  List<Producto> get productos => _productos;
  ResultadoLP? get resultadoProduccion => _resultadoProduccion;

  /// Resumen hablado de producción, o null si aún no hay resultado.
  String? get resumenHabladoProduccion {
    final r = _resultadoProduccion;
    if (r == null) return null;
    if (r.estado != EstadoSolucion.optimo) {
      return 'No se encontró una combinación factible de producción con los datos actuales.';
    }
    final buf = StringBuffer(
        'La utilidad máxima es ${r.z?.toStringAsFixed(2) ?? '0.00'} soles. ');
    for (var i = 0; i < r.nombresVariables.length && i < r.x.length; i++) {
      if (r.x[i] > 0.01) {
        buf.write('Produce ${r.x[i].toStringAsFixed(0)} unidades de ${r.nombresVariables[i]}. ');
      }
    }
    return buf.toString();
  }

  // ── Getters módulo rutas ──────────────────────────────────────
  List<Origen> get origenes => _origenes;
  List<Destino> get destinos => _destinos;
  List<List<double>> get costos => _costos;
  ResultadoLP? get resultadoRutas => _resultadoRutas;
  List<Origen> get origenesUsadosRuta => _origenes;
  List<Destino> get destinosUsadosRuta => _destinos;
  String? get notaBalanceRutas => _notaBalanceRutas;

  /// Resumen hablado de rutas, o null si aún no hay resultado.
  String? get resumenHabladoRutas {
    final r = _resultadoRutas;
    if (r == null) return null;
    return 'El costo mínimo de transporte es ${r.z?.toStringAsFixed(2) ?? '0.00'} soles, '
        'repartiendo entre ${_origenes.length} origen(es) y ${_destinos.length} destino(s).';
  }

  // ── Getters asistente de voz ────────────────────────────────────
  List<voz.MensajeChat> get historial => _historial;
  String get transcripcionParcial => _transcripcionParcial;
  bool get vozActiva => _vozActiva;

  // ── Constructor ───────────────────────────────────────────────
  AppState({required this.db}) {
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    _modo = db.getModo();
    _modelosGuardados = db.listarModelos();
    _perfilEmpresa = db.obtenerPerfil();
    await voice.init();

    _perfil = await storage.cargarPerfil();
    _productos = await storage.cargarProductos();
    _hiloDisponible = await storage.cargarHiloDisponible() ?? ejemplos.hiloEjemplo;
    _tiempoDisponible = await storage.cargarTiempoDisponible() ?? ejemplos.tiempoEjemplo;
    _origenes = await storage.cargarOrigenes();
    _destinos = await storage.cargarDestinos();
    _costos = await storage.cargarCostos();

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

  /// Cambia el nivel de detalle de las explicaciones (ejecutivo/técnico).
  void cambiarNivelExplicacion(voz.NivelExplicacion nivel) {
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
  /// Acepta tanto el perfil legado (Map, usado por config_screen.dart) como
  /// el nuevo [PerfilEmpresa] tipado (usado por perfil_screen.dart) — cada
  /// uno se persiste en su propio sistema de almacenamiento.
  Future<void> guardarPerfil(dynamic perfilData) async {
    if (perfilData is PerfilEmpresa) {
      _perfil = perfilData;
      await storage.guardarPerfil(perfilData);
    } else if (perfilData is Map<String, dynamic>) {
      _perfilEmpresa = perfilData;
      await db.guardarPerfil(perfilData);
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
    storage.guardarHiloDisponible(valor);
    notifyListeners();
  }

  void setTiempoDisponible(double valor) {
    _tiempoDisponible = valor;
    storage.guardarTiempoDisponible(valor);
    notifyListeners();
  }

  void agregarProducto() {
    _productos.add(Producto.vacio(_productos.length + 1));
    storage.guardarProductos(_productos);
    notifyListeners();
  }

  void actualizarProductoCampo(int index, String campo, String valor) {
    if (index < 0 || index >= _productos.length) return;
    final p = _productos[index];
    switch (campo) {
      case 'nombre':
        p.nombre = valor;
        break;
      case 'utilidad':
        p.utilidad = double.tryParse(valor) ?? p.utilidad;
        break;
      case 'hilo':
        p.hilo = double.tryParse(valor) ?? p.hilo;
        break;
      case 'tiempo':
        p.tiempo = double.tryParse(valor) ?? p.tiempo;
        break;
      case 'demanda':
        p.demanda = double.tryParse(valor) ?? p.demanda;
        break;
      case 'demandaMinima':
        p.demandaMinima = double.tryParse(valor) ?? p.demandaMinima;
        break;
    }
    storage.guardarProductos(_productos);
    notifyListeners();
  }

  void quitarProducto(int index) {
    if (index < 0 || index >= _productos.length) return;
    _productos.removeAt(index);
    storage.guardarProductos(_productos);
    notifyListeners();
  }

  Future<void> resolverProduccion() async {
    if (_productos.isEmpty) return;

    _resolviendo = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 50));

    final variables = _productos
        .map((p) => VariableLP(nombre: p.nombre, coeficienteObjetivo: p.utilidad))
        .toList();

    final restricciones = <RestriccionLP>[
      RestriccionLP(
        nombre: 'Hilo disponible',
        coeficientes: _productos.map((p) => p.hilo).toList(),
        tipo: TipoRestriccion.menorIgual,
        rhs: _hiloDisponible,
      ),
      RestriccionLP(
        nombre: 'Tiempo disponible',
        coeficientes: _productos.map((p) => p.tiempo).toList(),
        tipo: TipoRestriccion.menorIgual,
        rhs: _tiempoDisponible,
      ),
    ];

    for (var i = 0; i < _productos.length; i++) {
      final p = _productos[i];
      final indicador = List<double>.generate(_productos.length, (j) => j == i ? 1.0 : 0.0);
      if (p.demanda > 0) {
        restricciones.add(RestriccionLP(
          nombre: 'Demanda máxima ${p.nombre}',
          coeficientes: indicador,
          tipo: TipoRestriccion.menorIgual,
          rhs: p.demanda,
        ));
      }
      if (p.demandaMinima > 0) {
        restricciones.add(RestriccionLP(
          nombre: 'Demanda mínima ${p.nombre}',
          coeficientes: indicador,
          tipo: TipoRestriccion.mayorIgual,
          rhs: p.demandaMinima,
        ));
      }
    }

    final problema = ProblemaLP(
      nombre: 'Producción óptima',
      objetivo: TipoObjetivo.maximizar,
      variables: variables,
      restricciones: restricciones,
    );

    _resultadoProduccion = SolverLP.resolver(problema);
    _resolviendo = false;
    notifyListeners();
  }

  void cargarEjemploProduccion() {
    _hiloDisponible = ejemplos.hiloEjemplo;
    _tiempoDisponible = ejemplos.tiempoEjemplo;
    _productos = ejemplos.productosEjemplo();
    _resultadoProduccion = null;
    storage.guardarHiloDisponible(_hiloDisponible);
    storage.guardarTiempoDisponible(_tiempoDisponible);
    storage.guardarProductos(_productos);
    notifyListeners();
  }

  // ── Módulo de rutas / transporte ──────────────────────────────

  void agregarOrigen() {
    _origenes.add(Origen.vacio(_origenes.length + 1));
    _costos.add(List<double>.filled(_destinos.length, 0.0));
    storage.guardarOrigenes(_origenes);
    storage.guardarCostos(_costos);
    notifyListeners();
  }

  void quitarOrigen(int index) {
    if (index < 0 || index >= _origenes.length) return;
    _origenes.removeAt(index);
    if (index < _costos.length) _costos.removeAt(index);
    storage.guardarOrigenes(_origenes);
    storage.guardarCostos(_costos);
    notifyListeners();
  }

  void actualizarOrigenCampo(int index, String campo, String valor) {
    if (index < 0 || index >= _origenes.length) return;
    final o = _origenes[index];
    if (campo == 'nombre') {
      o.nombre = valor;
    } else if (campo == 'oferta') {
      o.oferta = double.tryParse(valor) ?? o.oferta;
    }
    storage.guardarOrigenes(_origenes);
    notifyListeners();
  }

  void agregarDestino() {
    _destinos.add(Destino.vacio(_destinos.length + 1));
    for (final fila in _costos) {
      fila.add(0.0);
    }
    storage.guardarDestinos(_destinos);
    storage.guardarCostos(_costos);
    notifyListeners();
  }

  void quitarDestino(int index) {
    if (index < 0 || index >= _destinos.length) return;
    _destinos.removeAt(index);
    for (final fila in _costos) {
      if (index < fila.length) fila.removeAt(index);
    }
    storage.guardarDestinos(_destinos);
    storage.guardarCostos(_costos);
    notifyListeners();
  }

  void actualizarDestinoCampo(int index, String campo, String valor) {
    if (index < 0 || index >= _destinos.length) return;
    final d = _destinos[index];
    if (campo == 'nombre') {
      d.nombre = valor;
    } else if (campo == 'demanda') {
      d.demanda = double.tryParse(valor) ?? d.demanda;
    }
    storage.guardarDestinos(_destinos);
    notifyListeners();
  }

  void actualizarCosto(int origenIdx, int destinoIdx, String valor) {
    if (origenIdx < 0 || origenIdx >= _costos.length) return;
    if (destinoIdx < 0 || destinoIdx >= _costos[origenIdx].length) return;
    _costos[origenIdx][destinoIdx] = double.tryParse(valor) ?? _costos[origenIdx][destinoIdx];
    storage.guardarCostos(_costos);
    notifyListeners();
  }

  Future<void> resolverRutas() async {
    if (_origenes.isEmpty || _destinos.isEmpty) return;

    _resolviendo = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 50));

    final problema = ProblemaTransporte(
      origenes: _origenes.map((o) => o.nombre).toList(),
      destinos: _destinos.map((d) => d.nombre).toList(),
      oferta: _origenes.map((o) => o.oferta).toList(),
      demanda: _destinos.map((d) => d.demanda).toList(),
      costos: _costos.map((fila) => List<double>.from(fila)).toList(),
    );

    final resultadoTransporte = solver.resolverTransporte(problema);

    final nD = _destinos.length;
    final xPlano = <double>[];
    for (var i = 0; i < resultadoTransporte.asignacion.length; i++) {
      for (var j = 0; j < nD; j++) {
        xPlano.add(resultadoTransporte.asignacion[i][j]);
      }
    }

    final holgurasOrigen = <HolguraRestriccion>[];
    for (var i = 0; i < _origenes.length; i++) {
      final usado = List.generate(nD, (j) => xPlano[i * nD + j])
          .fold(0.0, (a, b) => a + b);
      holgurasOrigen.add(HolguraRestriccion(
        rhs: _origenes[i].oferta,
        usado: usado,
        holgura: _origenes[i].oferta - usado,
        etiqueta: _origenes[i].nombre,
      ));
    }

    final notaBalance = resultadoTransporte.pasos
        .firstWhere((p) => p.contains('desbalanceado'), orElse: () => '');
    _notaBalanceRutas = notaBalance.isEmpty ? null : notaBalance;

    _resultadoRutas = ResultadoLP(
      estado: EstadoSolucion.optimo,
      valorOptimo: resultadoTransporte.costoTotal,
      valoresVariables: const {},
      x: xPlano,
      z: resultadoTransporte.costoTotal,
      nombresVariables: [
        for (final o in _origenes)
          for (final d in _destinos) '${o.nombre}→${d.nombre}',
      ],
      holguras: holgurasOrigen,
      // Mismo largo que holguras: tabla_trace.dart indexa resultado.duales[i]
      // hasta resultado.holguras.length. El método de transporte (MVP) no
      // calcula precios sombra, así que se dejan en null ('—' en la tabla).
      duales: List<double?>.filled(holgurasOrigen.length, null),
      iteraciones: resultadoTransporte.pasos.length,
      explicacionSimple:
          'Costo mínimo de transporte: ${resultadoTransporte.costoTotal.toStringAsFixed(2)}',
      explicacionDetallada:
          'Se usó el método: ${resultadoTransporte.metodoUsado}.\n'
          '${resultadoTransporte.pasos.join('\n')}',
    );

    _resolviendo = false;
    notifyListeners();
  }

  void cargarEjemploRutas() {
    _origenes = ejemplos.origenesEjemplo();
    _destinos = ejemplos.destinosEjemplo();
    _costos = ejemplos.costosEjemplo();
    _resultadoRutas = null;
    _notaBalanceRutas = null;
    storage.guardarOrigenes(_origenes);
    storage.guardarDestinos(_destinos);
    storage.guardarCostos(_costos);
    notifyListeners();
  }

  // ── Asistente de voz (panel_asistente.dart / nlu_service.dart) ──

  void alternarVoz(bool activo) {
    _vozActiva = activo;
    if (!activo) {
      voice.detenerHabla();
    }
    notifyListeners();
  }

  /// Interpreta [texto] (venga de teclado o de voz) con [NluService] y
  /// agrega el intercambio al historial del panel del asistente.
  void procesarComandoTexto(String texto) {
    _historial.add(voz.MensajeChat(autor: voz.AutorMensaje.usuario, texto: texto));
    notifyListeners();

    final respuesta = NluService.procesar(texto, this);
    _historial.add(voz.MensajeChat(autor: voz.AutorMensaje.sistema, texto: respuesta));
    notifyListeners();

    if (_vozActiva) {
      voice.hablar(respuesta);
    }
  }

  void iniciarEscucha() {
    voice.startListening(
      onResult: (texto) {
        _transcripcionParcial = '';
        if (texto.trim().isNotEmpty) {
          procesarComandoTexto(texto);
        }
        notifyListeners();
      },
      onPartial: (parcial) {
        _transcripcionParcial = parcial;
        notifyListeners();
      },
    );
    notifyListeners();
  }

  void detenerEscucha() {
    voice.stopListening();
    _transcripcionParcial = '';
    notifyListeners();
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
