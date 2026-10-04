import 'package:asistente_pl/models/lp_models.dart';
import 'package:asistente_pl/core/simplex_solver.dart';
import 'package:asistente_pl/core/branch_bound_solver.dart';
import 'package:asistente_pl/core/transporte_solver.dart';
import 'package:asistente_pl/core/hungaro_solver.dart';
import 'package:asistente_pl/core/grafico_solver.dart';
import 'package:asistente_pl/core/montecarlo_solver.dart';

/// Motor central que selecciona y ejecuta el solver adecuado.
class SolverEngine {
  final SimplexSolver _simplex = SimplexSolver();
  final BranchBoundSolver _branchBound = BranchBoundSolver();
  final TransporteSolver _transporte = TransporteSolver();
  final HungaroSolver _hungaro = HungaroSolver();
  final GraficoSolver _grafico = GraficoSolver();
  final MonteCarloSolver _montecarlo = MonteCarloSolver();

  /// Resuelve automáticamente seleccionando el mejor método.
  ResultadoLP resolver(ProblemaLP problema) {
    final metodo = problema.metodoPreferido ?? _seleccionarMetodo(problema);

    switch (metodo) {
      case MetodoSolucion.simplexDosFases:
        return _simplex.resolver(problema);

      case MetodoSolucion.branchAndBound:
        return _branchBound.resolver(problema);

      case MetodoSolucion.metodoGrafico:
        if (problema.numVariables == 2) {
          final r = _grafico.resolver(problema);
          return r.resultado;
        }
        return _simplex.resolver(problema);

      case MetodoSolucion.transporte:
      case MetodoSolucion.asignacionHungara:
      case MetodoSolucion.simplexDual:
      case MetodoSolucion.metaMetas:
        return _simplex.resolver(problema);
    }
  }

  /// Resuelve un problema de transporte.
  ResultadoTransporte resolverTransporte(ProblemaTransporte problema) {
    return _transporte.resolver(problema);
  }

  /// Resuelve un problema de asignación.
  ({List<int> asignacion, double costo}) resolverAsignacion(
      List<List<double>> costos) {
    return _hungaro.resolver(costos);
  }

  /// Resuelve con método gráfico (2 variables).
  ({ResultadoLP resultado, List<Punto> regionFactible, List<Recta> rectas})
      resolverGrafico(ProblemaLP problema) {
    return _grafico.resolver(problema);
  }

  /// Ejecuta simulación Monte Carlo.
  ResultadoMonteCarlo simularMonteCarlo(
    ProblemaLP problema, {
    int corridas = 500,
    double variacionPorcentual = 0.15,
  }) {
    return _montecarlo.simular(
      problema,
      corridas: corridas,
      variacionPorcentual: variacionPorcentual,
    );
  }

  /// Selecciona automáticamente el mejor método.
  MetodoSolucion _seleccionarMetodo(ProblemaLP problema) {
    if (problema.tieneEnteras) return MetodoSolucion.branchAndBound;
    if (problema.numVariables == 2) return MetodoSolucion.metodoGrafico;
    return MetodoSolucion.simplexDosFases;
  }

  /// Retorna una descripción del método seleccionado.
  String describirMetodo(ProblemaLP problema) {
    final metodo = problema.metodoPreferido ?? _seleccionarMetodo(problema);
    switch (metodo) {
      case MetodoSolucion.simplexDosFases:
        return 'Simplex (dos fases) — el método estándar para problemas de PL';
      case MetodoSolucion.simplexDual:
        return 'Simplex Dual — para reoptimización y análisis de sensibilidad';
      case MetodoSolucion.branchAndBound:
        return 'Branch & Bound — para variables que deben ser números enteros';
      case MetodoSolucion.metodoGrafico:
        return 'Método Gráfico — visualización de la solución con 2 variables';
      case MetodoSolucion.transporte:
        return 'Transporte (Vogel + MODI) — para distribución desde orígenes a destinos';
      case MetodoSolucion.asignacionHungara:
        return 'Método Húngaro — para asignar tareas a trabajadores al mínimo costo';
      case MetodoSolucion.metaMetas:
        return 'Programación por Metas — para múltiples objetivos priorizados';
    }
  }

  /// Lista los métodos disponibles con descripción.
  List<({MetodoSolucion metodo, String nombre, String descripcion, String icono})>
      metodosDisponibles() {
    return [
      (
        metodo: MetodoSolucion.simplexDosFases,
        nombre: 'Simplex',
        descripcion: 'Método estándar para maximizar/minimizar con restricciones lineales',
        icono: '\u{1F4CA}',
      ),
      (
        metodo: MetodoSolucion.branchAndBound,
        nombre: 'Enteros (B&B)',
        descripcion: 'Para cuando las cantidades deben ser números enteros',
        icono: '\u{1F522}',
      ),
      (
        metodo: MetodoSolucion.metodoGrafico,
        nombre: 'Gráfico',
        descripcion: 'Visualización con 2 variables — ideal para aprender',
        icono: '\u{1F4C8}',
      ),
      (
        metodo: MetodoSolucion.transporte,
        nombre: 'Transporte',
        descripcion: 'Distribución óptima desde fábricas a tiendas',
        icono: '\u{1F69A}',
      ),
      (
        metodo: MetodoSolucion.asignacionHungara,
        nombre: 'Asignación',
        descripcion: 'Asignar personas a tareas al menor costo',
        icono: '\u{1F465}',
      ),
    ];
  }
}
