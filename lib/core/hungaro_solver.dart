import 'dart:math';

/// Solver del método húngaro para problemas de asignación.
class HungaroSolver {
  /// Resuelve un problema de asignación NxN (minimización).
  /// Retorna la asignación óptima y su costo.
  ({List<int> asignacion, double costo}) resolver(List<List<double>> costMatrix) {
    final n = costMatrix.length;
    if (n == 0) return (asignacion: [], costo: 0);

    // Copiar y hacer cuadrada si es necesario
    final maxDim = costMatrix.fold(n, (mx, row) => max(mx, row.length));
    final mat = List.generate(maxDim, (i) =>
        List.generate(maxDim, (j) =>
            i < n && j < costMatrix[i].length ? costMatrix[i][j] : 0.0));

    // Paso 1: Restar mínimo de cada fila
    for (int i = 0; i < maxDim; i++) {
      final minVal = mat[i].reduce(min);
      for (int j = 0; j < maxDim; j++) {
        mat[i][j] -= minVal;
      }
    }

    // Paso 2: Restar mínimo de cada columna
    for (int j = 0; j < maxDim; j++) {
      double minVal = double.infinity;
      for (int i = 0; i < maxDim; i++) {
        if (mat[i][j] < minVal) minVal = mat[i][j];
      }
      for (int i = 0; i < maxDim; i++) {
        mat[i][j] -= minVal;
      }
    }

    // Asignar usando zeros
    final rowAssign = List<int>.filled(maxDim, -1);
    final colAssign = List<int>.filled(maxDim, -1);

    for (int iteracion = 0; iteracion < 100; iteracion++) {
      // Intentar asignación
      _resetAsignaciones(rowAssign, colAssign, maxDim);
      _asignarZeros(mat, rowAssign, colAssign, maxDim);

      int asignados = rowAssign.where((a) => a >= 0).length;
      if (asignados >= maxDim) break;

      // Encontrar líneas mínimas para cubrir zeros
      final rowCovered = List<bool>.filled(maxDim, false);
      final colCovered = List<bool>.filled(maxDim, false);
      _cubrirZeros(mat, rowAssign, colAssign, rowCovered, colCovered, maxDim);

      // Encontrar mínimo no cubierto
      double minUncovered = double.infinity;
      for (int i = 0; i < maxDim; i++) {
        for (int j = 0; j < maxDim; j++) {
          if (!rowCovered[i] && !colCovered[j]) {
            if (mat[i][j] < minUncovered) minUncovered = mat[i][j];
          }
        }
      }

      if (minUncovered == double.infinity || minUncovered == 0) break;

      // Restar de no cubiertos, sumar a doblemente cubiertos
      for (int i = 0; i < maxDim; i++) {
        for (int j = 0; j < maxDim; j++) {
          if (!rowCovered[i] && !colCovered[j]) {
            mat[i][j] -= minUncovered;
          } else if (rowCovered[i] && colCovered[j]) {
            mat[i][j] += minUncovered;
          }
        }
      }
    }

    // Calcular costo con la matriz original
    double costo = 0;
    for (int i = 0; i < n; i++) {
      if (rowAssign[i] >= 0 && rowAssign[i] < costMatrix[i].length) {
        costo += costMatrix[i][rowAssign[i]];
      }
    }

    return (asignacion: rowAssign.sublist(0, n), costo: costo);
  }

  void _resetAsignaciones(List<int> row, List<int> col, int n) {
    for (int i = 0; i < n; i++) {
      row[i] = -1;
      col[i] = -1;
    }
  }

  void _asignarZeros(List<List<double>> mat, List<int> rowA, List<int> colA, int n) {
    // Asignar zeros preferiendo filas/columnas con menos opciones
    for (int pass = 0; pass < n; pass++) {
      int bestRow = -1;
      int bestCol = -1;
      int minOpciones = n + 1;

      for (int i = 0; i < n; i++) {
        if (rowA[i] >= 0) continue;
        int opciones = 0;
        int lastJ = -1;
        for (int j = 0; j < n; j++) {
          if (colA[j] >= 0) continue;
          if (mat[i][j].abs() < 1e-8) {
            opciones++;
            lastJ = j;
          }
        }
        if (opciones > 0 && opciones < minOpciones) {
          minOpciones = opciones;
          bestRow = i;
          bestCol = lastJ;
        }
      }

      if (bestRow < 0) break;

      // Asignar el zero con menos alternativas en esa fila
      for (int j = 0; j < n; j++) {
        if (colA[j] >= 0) continue;
        if (mat[bestRow][j].abs() < 1e-8) {
          bestCol = j;
          break;
        }
      }

      rowA[bestRow] = bestCol;
      colA[bestCol] = bestRow;
    }
  }

  void _cubrirZeros(List<List<double>> mat, List<int> rowA, List<int> colA,
      List<bool> rowC, List<bool> colC, int n) {
    // Marcar filas sin asignación
    final markedRows = <int>{};
    final markedCols = <int>{};

    for (int i = 0; i < n; i++) {
      if (rowA[i] < 0) markedRows.add(i);
    }

    bool changed = true;
    while (changed) {
      changed = false;
      for (final i in markedRows.toList()) {
        for (int j = 0; j < n; j++) {
          if (!markedCols.contains(j) && mat[i][j].abs() < 1e-8) {
            markedCols.add(j);
            changed = true;
          }
        }
      }
      for (final j in markedCols.toList()) {
        if (colA[j] >= 0 && !markedRows.contains(colA[j])) {
          markedRows.add(colA[j]);
          changed = true;
        }
      }
    }

    // Cubrir: filas NO marcadas + columnas marcadas
    for (int i = 0; i < n; i++) {
      rowC[i] = !markedRows.contains(i);
    }
    for (int j = 0; j < n; j++) {
      colC[j] = markedCols.contains(j);
    }
  }
}
