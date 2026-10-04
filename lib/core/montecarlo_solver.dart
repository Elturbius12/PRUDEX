import 'dart:math';
import 'package:asistente_pl/models/lp_models.dart';
import 'package:asistente_pl/core/simplex_solver.dart';

/// Simulación Monte Carlo para análisis de robustez.
class MonteCarloSolver {
  final SimplexSolver _simplex = SimplexSolver();
  final Random _rng = Random(42);

  /// Ejecuta N simulaciones variando los coeficientes.
  ResultadoMonteCarlo simular(
    ProblemaLP problemaBase, {
    int corridas = 500,
    double variacionPorcentual = 0.15, // ±15% por defecto
  }) {
    final resultados = <double>[];
    int factibles = 0;

    for (int i = 0; i < corridas; i++) {
      // Generar variaciones aleatorias con distribución triangular
      final probVar = _variarProblema(problemaBase, variacionPorcentual);
      final resultado = _simplex.resolver(probVar);

      if (resultado.estado == EstadoSolucion.optimo && resultado.valorOptimo != null) {
        resultados.add(resultado.valorOptimo!);
        factibles++;
      }
    }

    if (resultados.isEmpty) {
      return ResultadoMonteCarlo(
        mediaObjetivo: 0,
        desviacionEstandar: 0,
        percentil5: 0,
        percentil95: 0,
        distribucion: [],
        probabilidadFactible: 0,
      );
    }

    resultados.sort();

    final media = resultados.fold(0.0, (s, v) => s + v) / resultados.length;
    final varianza = resultados.fold(0.0, (s, v) => s + (v - media) * (v - media)) /
        resultados.length;
    final stdDev = sqrt(varianza);

    final idx5 = (resultados.length * 0.05).floor().clamp(0, resultados.length - 1);
    final idx95 = (resultados.length * 0.95).floor().clamp(0, resultados.length - 1);

    return ResultadoMonteCarlo(
      mediaObjetivo: media,
      desviacionEstandar: stdDev,
      percentil5: resultados[idx5],
      percentil95: resultados[idx95],
      distribucion: resultados,
      probabilidadFactible: factibles / corridas,
    );
  }

  ProblemaLP _variarProblema(ProblemaLP base, double pct) {
    final variables = base.variables.map((v) {
      final factor = 1.0 + _triangular(-pct, pct);
      return VariableLP(
        nombre: v.nombre,
        coeficienteObjetivo: v.coeficienteObjetivo * factor,
        cotaInferior: v.cotaInferior,
        cotaSuperior: v.cotaSuperior,
        entera: v.entera,
      );
    }).toList();

    final restricciones = base.restricciones.map((r) {
      final factor = 1.0 + _triangular(-pct, pct);
      return RestriccionLP(
        nombre: r.nombre,
        coeficientes: r.coeficientes,
        tipo: r.tipo,
        rhs: r.rhs * factor,
      );
    }).toList();

    return ProblemaLP(
      nombre: base.nombre,
      objetivo: base.objetivo,
      variables: variables,
      restricciones: restricciones,
    );
  }

  /// Genera un valor con distribución triangular simétrica.
  double _triangular(double minV, double maxV) {
    final u = _rng.nextDouble();
    final mid = (minV + maxV) / 2;
    if (u < 0.5) {
      return minV + sqrt(u * (maxV - minV) * (mid - minV));
    } else {
      return maxV - sqrt((1 - u) * (maxV - minV) * (maxV - mid));
    }
  }
}
