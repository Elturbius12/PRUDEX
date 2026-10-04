import 'package:asistente_pl/models/lp_models.dart';
import 'package:asistente_pl/core/simplex_solver.dart';

/// Solver Branch & Bound para programación lineal entera (PLE).
class BranchBoundSolver {
  final SimplexSolver _simplex = SimplexSolver();
  int _nodosExplorados = 0;
  static const int _maxNodos = 10000;

  /// Resuelve un problema con variables enteras.
  ResultadoLP resolver(ProblemaLP problema) {
    final sw = Stopwatch()..start();
    _nodosExplorados = 0;

    // Resolver relajación
    final relax = _simplex.resolver(problema);
    if (relax.estado != EstadoSolucion.optimo) {
      sw.stop();
      return ResultadoLP(
        estado: relax.estado,
        tiempoSolucion: sw.elapsed,
        explicacionSimple: 'No se encontró solución factible para la relajación continua.',
      );
    }

    // Verificar si ya es entera
    if (_esSolucionEntera(problema, relax.valoresVariables)) {
      sw.stop();
      return ResultadoLP(
        estado: EstadoSolucion.optimo,
        valorOptimo: relax.valorOptimo,
        valoresVariables: relax.valoresVariables,
        pasos: relax.pasos,
        sensibilidad: relax.sensibilidad,
        preciosSombra: relax.preciosSombra,
        tiempoSolucion: sw.elapsed,
        explicacionSimple: 'La solución de la relajación ya es entera. ${relax.explicacionSimple}',
        explicacionDetallada: relax.explicacionDetallada,
      );
    }

    // Branch & Bound
    double mejorZ = problema.objetivo == TipoObjetivo.maximizar
        ? double.negativeInfinity
        : double.infinity;
    Map<String, double>? mejorSol;

    _branchBound(problema, mejorZ, mejorSol, (z, sol) {
      mejorZ = z;
      mejorSol = sol;
    });

    sw.stop();

    if (mejorSol == null) {
      return ResultadoLP(
        estado: EstadoSolucion.noFactible,
        tiempoSolucion: sw.elapsed,
        explicacionSimple: 'No existe solución entera factible.',
      );
    }

    return ResultadoLP(
      estado: EstadoSolucion.optimo,
      valorOptimo: mejorZ,
      valoresVariables: mejorSol!,
      tiempoSolucion: sw.elapsed,
      explicacionSimple: _generarExplicacion(problema, mejorSol!, mejorZ),
      explicacionDetallada: 'Branch & Bound: $_nodosExplorados nodos explorados.\n'
          '${_generarExplicacion(problema, mejorSol!, mejorZ)}',
    );
  }

  void _branchBound(
      ProblemaLP problema,
      double mejorZ,
      Map<String, double>? mejorSol,
      void Function(double, Map<String, double>) actualizarMejor) {
    if (_nodosExplorados >= _maxNodos) return;
    _nodosExplorados++;

    final resultado = _simplex.resolver(problema);
    if (resultado.estado != EstadoSolucion.optimo) return;

    final z = resultado.valorOptimo!;

    // Poda por cota
    if (problema.objetivo == TipoObjetivo.maximizar && z <= mejorZ) return;
    if (problema.objetivo == TipoObjetivo.minimizar && z >= mejorZ) return;

    // Verificar integralidad
    if (_esSolucionEntera(problema, resultado.valoresVariables)) {
      actualizarMejor(z, resultado.valoresVariables);
      return;
    }

    // Seleccionar variable fraccionaria
    int? varIdx;
    double maxFrac = 0;
    for (int i = 0; i < problema.variables.length; i++) {
      if (!problema.variables[i].entera) continue;
      final val = resultado.valoresVariables[problema.variables[i].nombre] ?? 0;
      final frac = val - val.floorToDouble();
      if (frac > 0.001 && frac < 0.999 && frac > maxFrac) {
        maxFrac = frac;
        varIdx = i;
      }
    }

    if (varIdx == null) return;

    final varNombre = problema.variables[varIdx].nombre;
    final val = resultado.valoresVariables[varNombre] ?? 0;
    final piso = val.floorToDouble();
    final techo = val.ceilToDouble();

    // Rama izquierda: x_i <= piso
    final probIzq = _agregarCota(problema, varIdx, piso, true);
    _branchBound(probIzq, mejorZ, mejorSol, actualizarMejor);

    // Rama derecha: x_i >= techo
    final probDer = _agregarCota(problema, varIdx, techo, false);
    _branchBound(probDer, mejorZ, mejorSol, actualizarMejor);
  }

  ProblemaLP _agregarCota(ProblemaLP prob, int varIdx, double cota, bool superior) {
    final nuevasR = List<RestriccionLP>.from(prob.restricciones);
    final coefs = List<double>.filled(prob.numVariables, 0.0);
    coefs[varIdx] = 1.0;

    nuevasR.add(RestriccionLP(
      nombre: '${prob.variables[varIdx].nombre} ${superior ? "≤" : "≥"} ${cota.toInt()}',
      coeficientes: coefs,
      tipo: superior ? TipoRestriccion.menorIgual : TipoRestriccion.mayorIgual,
      rhs: cota,
    ));

    return ProblemaLP(
      nombre: prob.nombre,
      objetivo: prob.objetivo,
      variables: prob.variables,
      restricciones: nuevasR,
      metodoPreferido: prob.metodoPreferido,
    );
  }

  bool _esSolucionEntera(ProblemaLP prob, Map<String, double> vals) {
    for (final v in prob.variables) {
      if (!v.entera) continue;
      final val = vals[v.nombre] ?? 0;
      if ((val - val.roundToDouble()).abs() > 0.001) return false;
    }
    return true;
  }

  String _generarExplicacion(ProblemaLP prob, Map<String, double> vals, double z) {
    final verbo = prob.objetivo == TipoObjetivo.maximizar ? 'ganancia máxima' : 'costo mínimo';
    final items = vals.entries
        .where((e) => e.value.abs() > 0.001)
        .map((e) => '${e.value.round()} de ${e.key}')
        .join(', ');
    return 'Con variables enteras, tu $verbo es ${z.toStringAsFixed(2)}. '
        'Produce: $items. '
        '(Se exploraron $_nodosExplorados nodos.)';
  }
}
