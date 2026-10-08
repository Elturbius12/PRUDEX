library;

/// Tipo de objetivo.
enum TipoObjetivo { maximizar, minimizar }

/// Alias de TipoObjetivo para compatibilidad con lp_solver.dart del usuario.
typedef TipoOptimizacion = TipoObjetivo;

/// Tipo de restricción.
enum TipoRestriccion { menorIgual, mayorIgual, igual }

/// Métodos de solución disponibles.
enum MetodoSolucion {
  simplexDosFases,
  simplexDual,
  branchAndBound,
  metodoGrafico,
  transporte,
  asignacionHungara,
  metaMetas,
}

/// Estado de la solución.
/// NOTA: infactible es alias de noFactible para compatibilidad.
enum EstadoSolucion { optimo, noFactible, infactible, noAcotado, multiples, enProceso }

/// Variable de decisión.
class VariableLP {
  final String nombre;
  final double coeficienteObjetivo;
  final double? cotaInferior;
  final double? cotaSuperior;
  final bool entera;

  VariableLP({
    required this.nombre,
    required this.coeficienteObjetivo,
    this.cotaInferior,
    this.cotaSuperior,
    this.entera = false,
  });

  Map<String, dynamic> toJson() => {
    'nombre': nombre,
    'coeficienteObjetivo': coeficienteObjetivo,
    'cotaInferior': cotaInferior,
    'cotaSuperior': cotaSuperior,
    'entera': entera,
  };

  factory VariableLP.fromJson(Map<String, dynamic> j) => VariableLP(
    nombre: j['nombre'] as String,
    coeficienteObjetivo: (j['coeficienteObjetivo'] as num).toDouble(),
    cotaInferior: (j['cotaInferior'] as num?)?.toDouble(),
    cotaSuperior: (j['cotaSuperior'] as num?)?.toDouble(),
    entera: j['entera'] as bool? ?? false,
  );
}

/// Restricción del modelo.
class RestriccionLP {
  final String nombre;
  final List<double> coeficientes;
  final TipoRestriccion tipo;
  final double rhs;

  RestriccionLP({
    required this.nombre,
    required this.coeficientes,
    required this.tipo,
    required this.rhs,
  });

  /// Alias de nombre para compatibilidad con lp_solver.dart del usuario.
  String get etiqueta => nombre;

  String get simbolo {
    switch (tipo) {
      case TipoRestriccion.menorIgual: return '≤';
      case TipoRestriccion.mayorIgual: return '≥';
      case TipoRestriccion.igual: return '=';
    }
  }

  Map<String, dynamic> toJson() => {
    'nombre': nombre,
    'coeficientes': coeficientes,
    'tipo': tipo.index,
    'rhs': rhs,
  };

  factory RestriccionLP.fromJson(Map<String, dynamic> j) => RestriccionLP(
    nombre: j['nombre'] as String,
    coeficientes: (j['coeficientes'] as List).map((e) => (e as num).toDouble()).toList(),
    tipo: TipoRestriccion.values[j['tipo'] as int],
    rhs: (j['rhs'] as num).toDouble(),
  );
}

/// Modelo completo de PL.
class ProblemaLP {
  String nombre;
  TipoObjetivo objetivo;
  List<VariableLP> variables;
  List<RestriccionLP> restricciones;
  MetodoSolucion? metodoPreferido;
  String? descripcionNegocio;
  DateTime creado;

  ProblemaLP({
    required this.nombre,
    required this.objetivo,
    required this.variables,
    required this.restricciones,
    this.metodoPreferido,
    this.descripcionNegocio,
    DateTime? creado,
  }) : creado = creado ?? DateTime.now();

  int get numVariables => variables.length;
  int get numRestricciones => restricciones.length;
  bool get tieneEnteras => variables.any((v) => v.entera);

  /// Para compatibilidad con lp_solver.dart del usuario.
  List<String> get nombresVariables => variables.map((v) => v.nombre).toList();

  /// Para compatibilidad con lp_solver.dart del usuario.
  List<double> get coeficientesObjetivo =>
      variables.map((v) => v.coeficienteObjetivo).toList();

  /// Alias de objetivo para compatibilidad con lp_solver.dart del usuario.
  TipoObjetivo get tipo => objetivo;

  Map<String, dynamic> toJson() => {
    'nombre': nombre,
    'objetivo': objetivo.index,
    'variables': variables.map((v) => v.toJson()).toList(),
    'restricciones': restricciones.map((r) => r.toJson()).toList(),
    'metodoPreferido': metodoPreferido?.index,
    'descripcionNegocio': descripcionNegocio,
    'creado': creado.toIso8601String(),
  };

  factory ProblemaLP.fromJson(Map<String, dynamic> j) => ProblemaLP(
    nombre: j['nombre'] as String,
    objetivo: TipoObjetivo.values[j['objetivo'] as int],
    variables: (j['variables'] as List).map((v) => VariableLP.fromJson(v)).toList(),
    restricciones:
        (j['restricciones'] as List).map((r) => RestriccionLP.fromJson(r)).toList(),
    metodoPreferido: j['metodoPreferido'] != null
        ? MetodoSolucion.values[j['metodoPreferido'] as int]
        : null,
    descripcionNegocio: j['descripcionNegocio'] as String?,
    creado: DateTime.parse(j['creado'] as String),
  );
}

/// Holgura de restricción — usado por lp_solver.dart del usuario.
class HolguraRestriccion {
  final double holgura;
  final double? precioSombra;
  final String? restriccion;
  final double? rhs;
  final double? usado;
  final TipoRestriccion? tipo;
  final String etiqueta;

  const HolguraRestriccion({
    this.holgura = 0.0,
    this.precioSombra,
    this.restriccion,
    this.rhs,
    this.usado,
    this.tipo,
    this.etiqueta = '',
  });
}

/// Paso del Simplex (para traza educativa).
class PasoSimplex {
  final int iteracion;
  final List<List<double>> tableau;
  final List<String> basicas;
  final Object? entrante;
  final Object? saliente;
  final double? pivote;
  final String explicacion;
  final List<double> filaCosto;

  PasoSimplex({
    int? iteracion,
    List<List<double>>? tableau,
    List<List<double>>? tabla,
    List<String>? basicas,
    List<String>? base,
    this.entrante,
    this.saliente,
    this.pivote,
    String? explicacion,
    String? nota,
    List<double>? filaCosto,
  })  : iteracion = iteracion ?? 0,
        tableau = tableau ?? tabla ?? const [],
        basicas = basicas ?? base ?? const [],
        explicacion = explicacion ?? nota ?? '',
        filaCosto = filaCosto ?? const [];

  /// Alias de [tableau] — convención usada por tabla_trace.dart.
  List<List<double>> get tabla => tableau;

  /// Alias de [basicas] — convención usada por tabla_trace.dart.
  List<String> get base => basicas;

  /// Alias de [explicacion] — convención usada por tabla_trace.dart.
  String get nota => explicacion;
}

/// Resultado del solver.
class ResultadoLP {
  final EstadoSolucion estado;
  final double? valorOptimo;
  final Map<String, double> valoresVariables;
  final List<PasoSimplex> pasos;
  final List<double>? preciosSombra;
  final AnalisisSensibilidad? sensibilidad;
  final Duration tiempoSolucion;
  final String? explicacionSimple;
  final String? explicacionDetallada;

  final List<double> x;
  final double? z;
  final List<String> nombresVariables;
  final List<String> nombresColumnas;
  final List<double?> duales;
  final int? iteraciones;

  // trace y holguras: internamente guardados como nullable, pero expuestos
  // como getters NO nulos (si no se pasan, caen a valores por defecto) para
  // que el código que hace resultado.trace.length / resultado.holguras[i]
  // funcione sin necesidad de '!' ni comprobaciones null.
  final List<PasoSimplex>? _traceInterno;
  final List<HolguraRestriccion>? _holgurasInterno;

  List<PasoSimplex> get trace => _traceInterno ?? pasos;
  List<HolguraRestriccion> get holguras => _holgurasInterno ?? const [];

  ResultadoLP({
    required this.estado,
    this.valorOptimo,
    this.valoresVariables = const {},
    this.pasos = const [],
    this.preciosSombra,
    this.sensibilidad,
    this.tiempoSolucion = Duration.zero,
    this.explicacionSimple,
    this.explicacionDetallada,
    List<double>? x,
    this.z,
    List<String>? nombresVariables,
    List<PasoSimplex>? trace,
    List<String>? nombresColumnas,
    List<double?>? duales,
    List<HolguraRestriccion>? holguras,
    this.iteraciones,
  })  : x = x ?? const [],
        nombresVariables = nombresVariables ?? const [],
        nombresColumnas = nombresColumnas ?? const [],
        duales = duales ?? const [],
        _traceInterno = trace,
        _holgurasInterno = holguras;
}

/// Análisis de sensibilidad.
class AnalisisSensibilidad {
  final List<RangoCoeficiente> rangosObjetivo;
  final List<RangoRHS> rangosRHS;
  final List<double> preciosSombra;
  final List<double> costosReducidos;

  AnalisisSensibilidad({
    required this.rangosObjetivo,
    required this.rangosRHS,
    required this.preciosSombra,
    required this.costosReducidos,
  });
}

class RangoCoeficiente {
  final String variable;
  final double valorActual;
  final double limiteInferior;
  final double limiteSuperior;

  RangoCoeficiente({
    required this.variable,
    required this.valorActual,
    required this.limiteInferior,
    required this.limiteSuperior,
  });
}

class RangoRHS {
  final String restriccion;
  final double valorActual;
  final double limiteInferior;
  final double limiteSuperior;
  final double precioSombra;

  RangoRHS({
    required this.restriccion,
    required this.valorActual,
    required this.limiteInferior,
    required this.limiteSuperior,
    required this.precioSombra,
  });
}

/// Escenario para simulación.
class Escenario {
  final String nombre;
  final Map<String, double> cambios;
  final ResultadoLP? resultado;

  Escenario({required this.nombre, required this.cambios, this.resultado});
}

/// Resultado Monte Carlo.
class ResultadoMonteCarlo {
  final double mediaObjetivo;
  final double desviacionEstandar;
  final double percentil5;
  final double percentil95;
  final List<double> distribucion;
  final double probabilidadFactible;

  ResultadoMonteCarlo({
    required this.mediaObjetivo,
    required this.desviacionEstandar,
    required this.percentil5,
    required this.percentil95,
    required this.distribucion,
    required this.probabilidadFactible,
  });
}

/// Problema de transporte.
class ProblemaTransporte {
  final List<String> origenes;
  final List<String> destinos;
  final List<double> oferta;
  final List<double> demanda;
  final List<List<double>> costos;

  ProblemaTransporte({
    required this.origenes,
    required this.destinos,
    required this.oferta,
    required this.demanda,
    required this.costos,
  });
}

/// Resultado de transporte.
class ResultadoTransporte {
  final List<List<double>> asignacion;
  final double costoTotal;
  final String metodoUsado;
  final List<String> pasos;

  ResultadoTransporte({
    required this.asignacion,
    required this.costoTotal,
    required this.metodoUsado,
    this.pasos = const [],
  });
}

/// Mensaje del chat conversacional.
class MensajeChat {
  final String id;
  final String texto;
  final bool esUsuario;
  final DateTime timestamp;
  final TipoMensaje tipo;
  final Map<String, dynamic>? datos;

  MensajeChat({
    required this.id,
    required this.texto,
    required this.esUsuario,
    DateTime? timestamp,
    this.tipo = TipoMensaje.texto,
    this.datos,
  }) : timestamp = timestamp ?? DateTime.now();
}

enum TipoMensaje {
  texto,
  modelo,
  resultado,
  grafico,
  tabla,
  sugerencia,
  cargando,
}

// NOTA: PerfilEmpresa, Producto, Origen y Destino NO se definen aquí.
// Sus definiciones reales y correctas viven en sus propios archivos
// (models/perfil_empresa.dart, models/producto.dart,
// models/origen_destino.dart) y son las que usan produccion_screen.dart,
// rutas_screen.dart, perfil_screen.dart, nlu_service.dart y StorageService.
// Duplicarlas aquí (como se hizo antes) provoca errores de "ambiguous
// import" en los widgets que importan ambos archivos a la vez.