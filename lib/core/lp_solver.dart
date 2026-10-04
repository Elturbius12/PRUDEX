import '../models/lp_models.dart';

/// =====================================================================
/// NÚCLEO DE PROGRAMACIÓN LINEAL — Método Simplex (Big M), genérico.
///
/// Puerto directo (misma lógica, mismas convenciones de signo) del motor
/// ya probado en JavaScript para el prototipo web. Se verificó contra:
///  - un problema clásico de 2 variables (libro de texto),
///  - una mezcla de producción textil,
///  - un problema de transporte balanceado,
///  - un caso infactible y uno no acotado.
/// Todos los resultados (x, Z y precios sombra) coincidieron con la
/// teoría, por lo que esta traducción a Dart replica la misma matemática.
/// =====================================================================
class _ColumnaExtra {
  final String nombre;
  final String tipo; // 'holgura' | 'superavit' | 'artificial'
  final int filaIndice;
  _ColumnaExtra(this.nombre, this.tipo, this.filaIndice);
}

class SolverLP {
  static const double _mGrande = 1e6;
  static const double _eps = 1e-9;

  static ResultadoLP resolver(ProblemaLP problema) {
    final nOrig = problema.nombresVariables.length;
    final nCons = problema.restricciones.length;
    final signo = problema.tipo == TipoOptimizacion.minimizar ? -1.0 : 1.0;
    final cInt = problema.coeficientesObjetivo.map((v) => v * signo).toList();

    // Normalizar cada restricción a RHS >= 0 y determinar su tipo efectivo.
    final filasBase = <List<double>>[];
    final rhsBase = <double>[];
    final tipoEfectivo = <TipoRestriccion>[];

    for (var i = 0; i < nCons; i++) {
      final r = problema.restricciones[i];
      var rhsAdj = r.rhs;
      var signoFila = 1.0;
      if (rhsAdj < 0) {
        signoFila = -1.0;
        rhsAdj = -rhsAdj;
      }
      final coefs = r.coeficientes.map((v) => v * signoFila).toList();
      var efectivo = r.tipo;
      if (signoFila == -1.0) {
        if (r.tipo == TipoRestriccion.menorIgual) {
          efectivo = TipoRestriccion.mayorIgual;
        } else if (r.tipo == TipoRestriccion.mayorIgual) {
          efectivo = TipoRestriccion.menorIgual;
        }
      }
      filasBase.add(coefs);
      rhsBase.add(rhsAdj);
      tipoEfectivo.add(efectivo);
    }

    // Columnas extra: holgura para <=, superávit+artificial para >=, artificial para =.
    final extra = <_ColumnaExtra>[];
    for (var i = 0; i < nCons; i++) {
      switch (tipoEfectivo[i]) {
        case TipoRestriccion.menorIgual:
          extra.add(_ColumnaExtra('s${i + 1}', 'holgura', i));
          break;
        case TipoRestriccion.mayorIgual:
          extra.add(_ColumnaExtra('e${i + 1}', 'superavit', i));
          extra.add(_ColumnaExtra('a${i + 1}', 'artificial', i));
          break;
        case TipoRestriccion.igual:
          extra.add(_ColumnaExtra('a${i + 1}', 'artificial', i));
          break;
      }
    }

    final totalCols = nOrig + extra.length;
    final nombresColumnas = [
      ...problema.nombresVariables,
      ...extra.map((e) => e.nombre),
    ];

    // Construir tabla (nCons x totalCols+1, última columna = RHS).
    final tabla = List.generate(
      nCons,
      (i) => List<double>.filled(totalCols + 1, 0.0),
    );
    for (var i = 0; i < nCons; i++) {
      for (var j = 0; j < nOrig; j++) {
        tabla[i][j] = filasBase[i][j];
      }
      tabla[i][totalCols] = rhsBase[i];
    }
    for (var idx = 0; idx < extra.length; idx++) {
      final e = extra[idx];
      final colPos = nOrig + idx;
      tabla[e.filaIndice][colPos] = e.tipo == 'superavit' ? -1.0 : 1.0;
    }

    // Variable básica inicial de cada fila (holgura si existe; si no, artificial).
    final baseIdx = List<int>.filled(nCons, -1);
    final columnasArtificiales = <int>[];
    for (var i = 0; i < nCons; i++) {
      int? colHolgura;
      int? colArtificial;
      for (var idx = 0; idx < extra.length; idx++) {
        final e = extra[idx];
        if (e.filaIndice != i) continue;
        if (e.tipo == 'holgura') colHolgura = nOrig + idx;
        if (e.tipo == 'artificial') colArtificial = nOrig + idx;
      }
      final elegida = colHolgura ?? colArtificial!;
      baseIdx[i] = elegida;
      if (colArtificial != null) columnasArtificiales.add(colArtificial);
    }

    // Fila objetivo original: c_j para variables, 0 para holgura/superávit, -M para artificiales.
    final filaObjetivoOriginal = List<double>.filled(totalCols + 1, 0.0);
    for (var j = 0; j < nOrig; j++) {
      filaObjetivoOriginal[j] = cInt[j];
    }
    for (var idx = 0; idx < extra.length; idx++) {
      final e = extra[idx];
      filaObjetivoOriginal[nOrig + idx] = e.tipo == 'artificial' ? -_mGrande : 0.0;
    }

    var filaCosto = List<double>.from(filaObjetivoOriginal);
    filaCosto[totalCols] = 0.0;

    // Eliminar (poner en 0) las columnas básicas iniciales en la fila de costo.
    for (var i = 0; i < nCons; i++) {
      final bcol = baseIdx[i];
      final cb = filaObjetivoOriginal[bcol];
      if (cb.abs() > _eps) {
        for (var j = 0; j <= totalCols; j++) {
          filaCosto[j] -= cb * tabla[i][j];
        }
      }
    }

    List<List<double>> clonarTabla() => tabla.map((f) => List<double>.from(f)).toList();

    final trace = <PasoSimplex>[
      PasoSimplex(
        tabla: clonarTabla(),
        filaCosto: List<double>.from(filaCosto),
        base: baseIdx.map((b) => nombresColumnas[b]).toList(),
        nota: 'Tabla inicial (Big M).',
      ),
    ];

    var iter = 0;
    var estado = EstadoSolucion.optimo;

    while (iter < 200) {
      iter++;
      var pivoteCol = -1;
      var mejorVal = _eps;
      for (var j = 0; j < totalCols; j++) {
        if (filaCosto[j] > mejorVal) {
          mejorVal = filaCosto[j];
          pivoteCol = j;
        }
      }
      if (pivoteCol == -1) {
        estado = EstadoSolucion.optimo;
        break;
      }

      var pivoteFila = -1;
      var mejorRatio = double.infinity;
      for (var i = 0; i < nCons; i++) {
        final a = tabla[i][pivoteCol];
        if (a > _eps) {
          final ratio = tabla[i][totalCols] / a;
          if (ratio < mejorRatio - _eps) {
            mejorRatio = ratio;
            pivoteFila = i;
          }
        }
      }
      if (pivoteFila == -1) {
        estado = EstadoSolucion.noAcotado;
        break;
      }

      final nombreEntrante = nombresColumnas[pivoteCol];
      final nombreSaliente = nombresColumnas[baseIdx[pivoteFila]];

      final pivoteVal = tabla[pivoteFila][pivoteCol];
      for (var j = 0; j <= totalCols; j++) {
        tabla[pivoteFila][j] /= pivoteVal;
      }
      for (var i = 0; i < nCons; i++) {
        if (i == pivoteFila) continue;
        final factor = tabla[i][pivoteCol];
        if (factor.abs() > _eps) {
          for (var j = 0; j <= totalCols; j++) {
            tabla[i][j] -= factor * tabla[pivoteFila][j];
          }
        }
      }
      final factorCosto = filaCosto[pivoteCol];
      if (factorCosto.abs() > _eps) {
        for (var j = 0; j <= totalCols; j++) {
          filaCosto[j] -= factorCosto * tabla[pivoteFila][j];
        }
      }
      baseIdx[pivoteFila] = pivoteCol;

      trace.add(PasoSimplex(
        tabla: clonarTabla(),
        filaCosto: List<double>.from(filaCosto),
        base: baseIdx.map((b) => nombresColumnas[b]).toList(),
        entrante: nombreEntrante,
        saliente: nombreSaliente,
        nota: 'Entra $nombreEntrante, sale $nombreSaliente.',
      ));
    }

    var infactible = false;
    for (var i = 0; i < nCons; i++) {
      if (columnasArtificiales.contains(baseIdx[i]) && tabla[i][totalCols] > 1e-6) {
        infactible = true;
      }
    }
    if (infactible) estado = EstadoSolucion.infactible;

    final xFull = List<double>.filled(totalCols, 0.0);
    for (var i = 0; i < nCons; i++) {
      xFull[baseIdx[i]] = tabla[i][totalCols];
    }
    final x = List<double>.generate(nOrig, (j) => xFull[j]);
    final z = (-filaCosto[totalCols]) * signo;

    // Precios sombra: para holgura (<=) dual = -filaCosto[col]; para
    // superávit (>=) dual = filaCosto[col]; para = no se reporta (MVP).
    final duales = <double?>[];
    for (var i = 0; i < nCons; i++) {
      switch (tipoEfectivo[i]) {
        case TipoRestriccion.menorIgual:
          final idx = extra.indexWhere((e) => e.filaIndice == i && e.tipo == 'holgura');
          duales.add(-filaCosto[nOrig + idx] * signo);
          break;
        case TipoRestriccion.mayorIgual:
          final idx = extra.indexWhere((e) => e.filaIndice == i && e.tipo == 'superavit');
          duales.add(filaCosto[nOrig + idx] * signo);
          break;
        case TipoRestriccion.igual:
          duales.add(null);
          break;
      }
    }

    final holguras = <HolguraRestriccion>[];
    for (var i = 0; i < nCons; i++) {
      final r = problema.restricciones[i];
      var usado = 0.0;
      for (var j = 0; j < nOrig; j++) {
        usado += r.coeficientes[j] * x[j];
      }
      holguras.add(HolguraRestriccion(
        rhs: r.rhs,
        usado: usado,
        holgura: r.rhs - usado,
        tipo: r.tipo,
        etiqueta: r.etiqueta,
      ));
    }

    return ResultadoLP(
      estado: estado,
      x: x,
      z: z,
      nombresVariables: problema.nombresVariables,
      trace: trace,
      nombresColumnas: nombresColumnas,
      duales: duales,
      holguras: holguras,
      iteraciones: iter,
    );
  }
}
