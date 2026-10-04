import 'dart:math';
import 'package:asistente_pl/models/lp_models.dart';

/// Solver Simplex Dos Fases completo.
class SimplexSolver {
  /// Resuelve un ProblemaLP usando el método Simplex de dos fases.
  ResultadoLP resolver(ProblemaLP problema) {
    final sw = Stopwatch()..start();
    final n = problema.numVariables;
    final m = problema.numRestricciones;
    final pasos = <PasoSimplex>[];

    // Determinar variables auxiliares necesarias
    int numSlack = 0;
    int numArtificial = 0;
    final slackIndices = <int>[];
    final artificialIndices = <int>[];
    final tiposR = <TipoRestriccion>[];

    for (final r in problema.restricciones) {
      tiposR.add(r.tipo);
      switch (r.tipo) {
        case TipoRestriccion.menorIgual:
          slackIndices.add(n + numSlack + numArtificial);
          numSlack++;
          break;
        case TipoRestriccion.mayorIgual:
          slackIndices.add(n + numSlack + numArtificial);
          numSlack++;
          artificialIndices.add(n + numSlack + numArtificial);
          numArtificial++;
          break;
        case TipoRestriccion.igual:
          slackIndices.add(-1); // No slack
          artificialIndices.add(n + numSlack + numArtificial);
          numArtificial++;
          break;
      }
    }

    final totalCols = n + numSlack + numArtificial + 1; // +1 para RHS
    final basicas = List<int>.filled(m, 0);

    // Construir tableau
    final tableau = List.generate(m + 1, (_) => List<double>.filled(totalCols, 0.0));

    int slackIdx = 0;
    int artIdx = 0;

    for (int i = 0; i < m; i++) {
      // Coeficientes originales
      for (int j = 0; j < n; j++) {
        tableau[i][j] = problema.restricciones[i].coeficientes[j];
      }
      // RHS
      double rhs = problema.restricciones[i].rhs;

      // Asegurar RHS >= 0
      if (rhs < 0) {
        for (int j = 0; j < totalCols; j++) {
          tableau[i][j] = -tableau[i][j];
        }
        rhs = -rhs;
        // Invertir tipo de restricción
        tiposR[i] = tiposR[i] == TipoRestriccion.menorIgual
            ? TipoRestriccion.mayorIgual
            : tiposR[i] == TipoRestriccion.mayorIgual
                ? TipoRestriccion.menorIgual
                : TipoRestriccion.igual;
      }
      tableau[i][totalCols - 1] = rhs;

      // Slack / surplus / artificial
      switch (tiposR[i]) {
        case TipoRestriccion.menorIgual:
          final si = n + slackIdx;
          tableau[i][si] = 1.0;
          basicas[i] = si;
          slackIdx++;
          break;
        case TipoRestriccion.mayorIgual:
          final si = n + slackIdx;
          tableau[i][si] = -1.0;
          slackIdx++;
          final ai = n + slackIdx + artIdx;
          tableau[i][ai] = 1.0;
          basicas[i] = ai;
          artIdx++;
          break;
        case TipoRestriccion.igual:
          final ai = n + slackIdx + artIdx;
          tableau[i][ai] = 1.0;
          basicas[i] = ai;
          artIdx++;
          break;
      }
    }

    // ── FASE 1 (si hay artificiales) ─────────────────────────────
    bool necesitaFase1 = numArtificial > 0;
    if (necesitaFase1) {
      // Fila objetivo Fase 1: minimizar suma de artificiales
      // w = sum(artificiales)
      final wRow = List<double>.filled(totalCols, 0.0);
      for (int i = 0; i < m; i++) {
        if (basicas[i] >= n + numSlack) {
          // Es artificial, restar su fila de w
          for (int j = 0; j < totalCols; j++) {
            wRow[j] -= tableau[i][j];
          }
        }
      }
      tableau[m] = wRow;

      pasos.add(PasoSimplex(
        iteracion: 0,
        tableau: _copiarTableau(tableau),
        basicas: _nombresBasicas(basicas, problema),
        explicacion: 'Fase 1: Buscar solución básica factible',
      ));

      // Iterar Fase 1
      final fase1Ok = _iterarSimplex(tableau, basicas, m, totalCols, pasos, 'Fase 1', problema);
      if (!fase1Ok) {
        sw.stop();
        return ResultadoLP(
          estado: EstadoSolucion.noFactible,
          tiempoSolucion: sw.elapsed,
          pasos: pasos,
          explicacionSimple: 'El problema no tiene solución factible. Las restricciones son contradictorias.',
          explicacionDetallada: 'Durante la Fase 1 del Simplex, no se pudo reducir el valor de la función auxiliar a cero, lo que indica que el conjunto de restricciones es incompatible.',
        );
      }

      // Verificar que w = 0
      if (tableau[m][totalCols - 1].abs() > 1e-8) {
        sw.stop();
        return ResultadoLP(
          estado: EstadoSolucion.noFactible,
          tiempoSolucion: sw.elapsed,
          pasos: pasos,
          explicacionSimple: 'No existe combinación de productos que cumpla todas las restricciones.',
          explicacionDetallada: 'La Fase 1 terminó con w = ${tableau[m][totalCols - 1].toStringAsFixed(4)} ≠ 0. El sistema de restricciones no tiene solución.',
        );
      }
    }

    // ── FASE 2 ───────────────────────────────────────────────────
    // Fila objetivo original
    final objRow = List<double>.filled(totalCols, 0.0);
    for (int j = 0; j < n; j++) {
      double c = problema.variables[j].coeficienteObjetivo;
      if (problema.objetivo == TipoObjetivo.maximizar) {
        objRow[j] = -c;  // max c^T x → min -c^T x
      } else {
        objRow[j] = c;
      }
    }
    // Hacer ceros en columnas básicas
    for (int i = 0; i < m; i++) {
      if (objRow[basicas[i]].abs() > 1e-12) {
        final factor = objRow[basicas[i]];
        for (int j = 0; j < totalCols; j++) {
          objRow[j] -= factor * tableau[i][j];
        }
      }
    }
    tableau[m] = objRow;

    pasos.add(PasoSimplex(
      iteracion: pasos.length,
      tableau: _copiarTableau(tableau),
      basicas: _nombresBasicas(basicas, problema),
      explicacion: necesitaFase1
          ? 'Fase 2: Optimizar función objetivo original'
          : 'Optimizando función objetivo',
    ));

    final fase2Ok = _iterarSimplex(tableau, basicas, m, totalCols, pasos, 'Fase 2', problema);
    sw.stop();

    if (!fase2Ok) {
      return ResultadoLP(
        estado: EstadoSolucion.noAcotado,
        tiempoSolucion: sw.elapsed,
        pasos: pasos,
        explicacionSimple: 'La ganancia puede crecer sin límite. Revisa si falta alguna restricción.',
        explicacionDetallada: 'La variable entrante no tiene restricción superior en ninguna fila (todas las ratios son negativas o cero). El problema es no acotado.',
      );
    }

    // Extraer solución
    final valores = <String, double>{};
    for (int j = 0; j < n; j++) {
      valores[problema.variables[j].nombre] = 0.0;
    }
    for (int i = 0; i < m; i++) {
      if (basicas[i] < n) {
        valores[problema.variables[basicas[i]].nombre] = tableau[i][totalCols - 1];
      }
    }

    double z = -tableau[m][totalCols - 1];
    if (problema.objetivo == TipoObjetivo.minimizar) z = tableau[m][totalCols - 1];

    // Precios sombra
    final sombra = <double>[];
    for (int i = 0; i < m; i++) {
      sombra.add(tableau[m][n + i].abs() < 1e-10 ? 0.0 : tableau[m][n + i]);
    }

    // Análisis de sensibilidad
    final sensibilidad = _calcularSensibilidad(tableau, basicas, problema, m, n, totalCols);

    return ResultadoLP(
      estado: EstadoSolucion.optimo,
      valorOptimo: z,
      valoresVariables: valores,
      pasos: pasos,
      preciosSombra: sombra,
      sensibilidad: sensibilidad,
      tiempoSolucion: sw.elapsed,
      explicacionSimple: _generarExplicacionSimple(problema, valores, z),
      explicacionDetallada: _generarExplicacionDetallada(problema, valores, z, sombra),
    );
  }

  /// Itera el Simplex hasta optimalidad.
  bool _iterarSimplex(List<List<double>> tableau, List<int> basicas,
      int m, int totalCols, List<PasoSimplex> pasos, String fase, ProblemaLP prob) {
    int maxIter = 1000;

    for (int iter = 0; iter < maxIter; iter++) {
      // Encontrar variable entrante (más negativa en fila objetivo)
      int entrante = -1;
      double minVal = -1e-8;
      for (int j = 0; j < totalCols - 1; j++) {
        if (tableau[m][j] < minVal) {
          minVal = tableau[m][j];
          entrante = j;
        }
      }
      if (entrante == -1) return true; // Óptimo

      // Encontrar variable saliente (mínimo ratio)
      int saliente = -1;
      double minRatio = double.infinity;
      for (int i = 0; i < m; i++) {
        if (tableau[i][entrante] > 1e-8) {
          final ratio = tableau[i][totalCols - 1] / tableau[i][entrante];
          if (ratio < minRatio) {
            minRatio = ratio;
            saliente = i;
          }
        }
      }
      if (saliente == -1) return false; // No acotado

      final pivote = tableau[saliente][entrante];

      // Pivotear
      for (int j = 0; j < totalCols; j++) {
        tableau[saliente][j] /= pivote;
      }
      for (int i = 0; i <= m; i++) {
        if (i != saliente && tableau[i][entrante].abs() > 1e-12) {
          final factor = tableau[i][entrante];
          for (int j = 0; j < totalCols; j++) {
            tableau[i][j] -= factor * tableau[saliente][j];
          }
        }
      }

      basicas[saliente] = entrante;

      pasos.add(PasoSimplex(
        iteracion: pasos.length,
        tableau: _copiarTableau(tableau),
        basicas: _nombresBasicas(basicas, prob),
        entrante: entrante,
        saliente: saliente,
        pivote: pivote,
        explicacion: '$fase — Iteración ${iter + 1}: '
            'Entra ${_nombreColumna(entrante, prob)}, '
            'sale ${_nombreColumna(basicas[saliente], prob)}, '
            'pivote = ${pivote.toStringAsFixed(4)}',
      ));
    }
    return true;
  }

  AnalisisSensibilidad? _calcularSensibilidad(
      List<List<double>> tableau, List<int> basicas,
      ProblemaLP prob, int m, int n, int totalCols) {
    try {
      final rangosObj = <RangoCoeficiente>[];
      final rangosRHS = <RangoRHS>[];
      final sombra = <double>[];
      final costosRed = <double>[];

      // Costos reducidos
      for (int j = 0; j < n; j++) {
        costosRed.add(tableau[m][j]);
      }

      // Rangos de coeficientes objetivo
      for (int j = 0; j < n; j++) {
        double inferior = double.negativeInfinity;
        double superior = double.infinity;

        final esBasica = basicas.contains(j);
        if (!esBasica) {
          // No básica: el rango es c_j + costo_reducido
          superior = prob.variables[j].coeficienteObjetivo + tableau[m][j].abs();
          inferior = prob.variables[j].coeficienteObjetivo - tableau[m][j].abs();
        } else {
          // Básica: calcular por ratios
          final filaIdx = basicas.indexOf(j);
          for (int k = 0; k < totalCols - 1; k++) {
            if (k != j && !basicas.contains(k) && tableau[filaIdx][k].abs() > 1e-10) {
              final ratio = tableau[m][k] / tableau[filaIdx][k];
              if (tableau[filaIdx][k] > 0) {
                superior = min(superior, ratio);
              } else {
                inferior = max(inferior, ratio);
              }
            }
          }
          inferior = prob.variables[j].coeficienteObjetivo + inferior;
          superior = prob.variables[j].coeficienteObjetivo + superior;
        }

        rangosObj.add(RangoCoeficiente(
          variable: prob.variables[j].nombre,
          valorActual: prob.variables[j].coeficienteObjetivo,
          limiteInferior: inferior.isFinite ? inferior : -9999,
          limiteSuperior: superior.isFinite ? superior : 9999,
        ));
      }

      // Precios sombra y rangos RHS
      for (int i = 0; i < m; i++) {
        final ps = tableau[m][n + i].abs() < 1e-10 ? 0.0 : -tableau[m][n + i];
        sombra.add(ps);

        double infRHS = double.negativeInfinity;
        double supRHS = double.infinity;

        for (int k = 0; k < m; k++) {
          if (tableau[k][n + i].abs() > 1e-10) {
            final ratio = tableau[k][totalCols - 1] / tableau[k][n + i];
            if (tableau[k][n + i] > 0) {
              supRHS = min(supRHS, ratio);
            } else {
              infRHS = max(infRHS, -ratio);
            }
          }
        }

        rangosRHS.add(RangoRHS(
          restriccion: prob.restricciones[i].nombre,
          valorActual: prob.restricciones[i].rhs,
          limiteInferior: infRHS.isFinite
              ? prob.restricciones[i].rhs - infRHS
              : -9999,
          limiteSuperior: supRHS.isFinite
              ? prob.restricciones[i].rhs + supRHS
              : 9999,
          precioSombra: ps,
        ));
      }

      return AnalisisSensibilidad(
        rangosObjetivo: rangosObj,
        rangosRHS: rangosRHS,
        preciosSombra: sombra,
        costosReducidos: costosRed,
      );
    } catch (_) {
      return null;
    }
  }

  String _generarExplicacionSimple(ProblemaLP prob, Map<String, double> vals, double z) {
    final buf = StringBuffer();
    final verbo = prob.objetivo == TipoObjetivo.maximizar ? 'ganancia máxima' : 'costo mínimo';
    buf.write('Tu $verbo es de ${z.toStringAsFixed(2)}. ');

    final productivos = vals.entries.where((e) => e.value > 0.001).toList();
    if (productivos.isNotEmpty) {
      buf.write('Debes producir: ');
      buf.writeAll(
        productivos.map((e) => '${e.value.toStringAsFixed(1)} de ${e.key}'),
        ', ',
      );
      buf.write('.');
    }
    return buf.toString();
  }

  String _generarExplicacionDetallada(
      ProblemaLP prob, Map<String, double> vals, double z, List<double> sombra) {
    final buf = StringBuffer();
    buf.writeln('=== RESULTADO DETALLADO ===\n');
    buf.writeln('Objetivo (${prob.objetivo.name}): Z = ${z.toStringAsFixed(4)}\n');

    buf.writeln('Variables de decisión:');
    for (final e in vals.entries) {
      buf.writeln('  ${e.key} = ${e.value.toStringAsFixed(4)}');
    }

    if (sombra.isNotEmpty) {
      buf.writeln('\nPrecios sombra (valor marginal):');
      for (int i = 0; i < sombra.length && i < prob.restricciones.length; i++) {
        final r = prob.restricciones[i];
        buf.writeln('  ${r.nombre}: ${sombra[i].toStringAsFixed(4)}');
        if (sombra[i].abs() > 0.001) {
          buf.writeln('    → Cada unidad adicional de ${r.nombre} cambia Z en ${sombra[i].toStringAsFixed(4)}');
        }
      }
    }

    return buf.toString();
  }

  List<List<double>> _copiarTableau(List<List<double>> t) =>
      t.map((row) => List<double>.from(row)).toList();

  List<String> _nombresBasicas(List<int> basicas, ProblemaLP prob) =>
      basicas.map((i) => _nombreColumna(i, prob)).toList();

  String _nombreColumna(int idx, ProblemaLP prob) {
    if (idx < prob.numVariables) return prob.variables[idx].nombre;
    return 'S${idx - prob.numVariables + 1}';
  }
}
