import 'package:asistente_pl/models/lp_models.dart';

/// Solver para problemas de transporte.
class TransporteSolver {
  /// Resuelve usando esquina noroeste + MODI.
  ResultadoTransporte resolver(ProblemaTransporte prob) {
    final m = prob.origenes.length;
    final n = prob.destinos.length;
    final pasos = <String>[];

    // Balancear si es necesario
    var oferta = List<double>.from(prob.oferta);
    var demanda = List<double>.from(prob.demanda);
    var costos = prob.costos.map((r) => List<double>.from(r)).toList();

    final totalOferta = oferta.fold(0.0, (a, b) => a + b);
    final totalDemanda = demanda.fold(0.0, (a, b) => a + b);

    if ((totalOferta - totalDemanda).abs() > 1e-8) {
      if (totalOferta > totalDemanda) {
        demanda.add(totalOferta - totalDemanda);
        for (var row in costos) {
          row.add(0.0);
        }
        pasos.add('Problema desbalanceado: se agregó destino ficticio con demanda ${(totalOferta - totalDemanda).toStringAsFixed(1)}');
      } else {
        oferta.add(totalDemanda - totalOferta);
        costos.add(List.filled(demanda.length, 0.0));
        pasos.add('Problema desbalanceado: se agregó origen ficticio con oferta ${(totalDemanda - totalOferta).toStringAsFixed(1)}');
      }
    }

    final mf = oferta.length;
    final nf = demanda.length;

    // Solución inicial: Vogel
    final asignacion = _vogel(oferta, demanda, costos, mf, nf, pasos);

    // Optimizar con MODI
    _modi(asignacion, costos, mf, nf, pasos);

    // Calcular costo total
    double costoTotal = 0;
    for (int i = 0; i < mf; i++) {
      for (int j = 0; j < nf; j++) {
        costoTotal += asignacion[i][j] * costos[i][j];
      }
    }

    // Recortar a dimensiones originales
    final asigFinal = List.generate(
      m, (i) => List.generate(n, (j) => asignacion[i][j]),
    );

    return ResultadoTransporte(
      asignacion: asigFinal,
      costoTotal: costoTotal,
      metodoUsado: 'Aproximación de Vogel + MODI',
      pasos: pasos,
    );
  }

  /// Método de Vogel para solución inicial.
  List<List<double>> _vogel(
      List<double> oferta, List<double> demanda,
      List<List<double>> costos, int m, int n, List<String> pasos) {
    final asig = List.generate(m, (_) => List<double>.filled(n, 0.0));
    final of2 = List<double>.from(oferta);
    final dm2 = List<double>.from(demanda);
    final usedRows = List<bool>.filled(m, false);
    final usedCols = List<bool>.filled(n, false);

    pasos.add('Método de Vogel: Calcular penalidades por fila y columna');

    int asignaciones = 0;
    final total = m + n - 1;

    while (asignaciones < total) {
      // Calcular penalidades
      double maxPen = -1;
      int bestI = -1, bestJ = -1;

      // Penalidades por fila
      for (int i = 0; i < m; i++) {
        if (usedRows[i]) continue;
        final vals = <_CostoIdx>[];
        for (int j = 0; j < n; j++) {
          if (!usedCols[j]) vals.add(_CostoIdx(costos[i][j], j));
        }
        if (vals.length < 2) {
          if (vals.length == 1) {
            final pen = vals[0].costo;
            if (pen > maxPen) {
              maxPen = pen;
              bestI = i;
              bestJ = vals[0].idx;
            }
          }
          continue;
        }
        vals.sort((a, b) => a.costo.compareTo(b.costo));
        final pen = vals[1].costo - vals[0].costo;
        if (pen > maxPen) {
          maxPen = pen;
          bestI = i;
          bestJ = vals[0].idx;
        }
      }

      // Penalidades por columna
      for (int j = 0; j < n; j++) {
        if (usedCols[j]) continue;
        final vals = <_CostoIdx>[];
        for (int i = 0; i < m; i++) {
          if (!usedRows[i]) vals.add(_CostoIdx(costos[i][j], i));
        }
        if (vals.length < 2) {
          if (vals.length == 1) {
            final pen = vals[0].costo;
            if (pen > maxPen) {
              maxPen = pen;
              bestI = vals[0].idx;
              bestJ = j;
            }
          }
          continue;
        }
        vals.sort((a, b) => a.costo.compareTo(b.costo));
        final pen = vals[1].costo - vals[0].costo;
        if (pen > maxPen) {
          maxPen = pen;
          bestI = vals[0].idx;
          bestJ = j;
        }
      }

      if (bestI == -1 || bestJ == -1) break;

      final cantidad = of2[bestI] < dm2[bestJ] ? of2[bestI] : dm2[bestJ];
      asig[bestI][bestJ] = cantidad;
      of2[bestI] -= cantidad;
      dm2[bestJ] -= cantidad;

      if (of2[bestI] < 1e-8) usedRows[bestI] = true;
      if (dm2[bestJ] < 1e-8) usedCols[bestJ] = true;

      asignaciones++;
    }

    pasos.add('Solución inicial de Vogel completada');
    return asig;
  }

  /// Método MODI para optimizar.
  void _modi(List<List<double>> asig, List<List<double>> costos,
      int m, int n, List<String> pasos) {
    int maxIter = 100;
    for (int iter = 0; iter < maxIter; iter++) {
      // Calcular u_i y v_j
      final u = List<double?>.filled(m, null);
      final v = List<double?>.filled(n, null);
      u[0] = 0;

      bool changed = true;
      while (changed) {
        changed = false;
        for (int i = 0; i < m; i++) {
          for (int j = 0; j < n; j++) {
            if (asig[i][j] > 1e-8 || _esBasica(asig, i, j, m, n)) {
              if (u[i] != null && v[j] == null) {
                v[j] = costos[i][j] - u[i]!;
                changed = true;
              } else if (v[j] != null && u[i] == null) {
                u[i] = costos[i][j] - v[j]!;
                changed = true;
              }
            }
          }
        }
      }

      // Calcular costos reducidos
      double minCR = 0;
      int entI = -1, entJ = -1;
      for (int i = 0; i < m; i++) {
        for (int j = 0; j < n; j++) {
          if (asig[i][j] < 1e-8 && u[i] != null && v[j] != null) {
            final cr = costos[i][j] - u[i]! - v[j]!;
            if (cr < minCR - 1e-8) {
              minCR = cr;
              entI = i;
              entJ = j;
            }
          }
        }
      }

      if (entI == -1) {
        pasos.add('MODI: Solución óptima encontrada en iteración ${iter + 1}');
        return;
      }

      // Encontrar ciclo y reasignar (simplificado)
      _reasignarCiclo(asig, entI, entJ, m, n);
      pasos.add('MODI iteración ${iter + 1}: Celda ($entI,$entJ) mejora en ${minCR.toStringAsFixed(2)}');
    }
  }

  bool _esBasica(List<List<double>> asig, int i, int j, int m, int n) {
    return asig[i][j] > 1e-8;
  }

  void _reasignarCiclo(List<List<double>> asig, int entI, int entJ, int m, int n) {
    // Buscar stepping stone path simplificado
    // Encontrar la celda que pueda cerrar un ciclo rectangular
    for (int i = 0; i < m; i++) {
      if (i == entI) continue;
      if (asig[i][entJ] < 1e-8) continue;
      for (int j = 0; j < n; j++) {
        if (j == entJ) continue;
        if (asig[entI][j] < 1e-8) continue;
        if (asig[i][j] < 1e-8) continue;

        // Ciclo: (entI,entJ)+ (i,entJ)- (i,j)+ (entI,j)-
        final theta = [asig[i][entJ], asig[entI][j]].reduce((a, b) => a < b ? a : b);
        asig[entI][entJ] += theta;
        asig[i][entJ] -= theta;
        asig[i][j] += theta;
        asig[entI][j] -= theta;
        return;
      }
    }
  }
}

class _CostoIdx {
  final double costo;
  final int idx;
  _CostoIdx(this.costo, this.idx);
}
