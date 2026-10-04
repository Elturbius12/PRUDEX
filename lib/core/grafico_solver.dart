import 'dart:math';
import 'package:asistente_pl/models/lp_models.dart';

/// Solver para método gráfico (2 variables).
class GraficoSolver {
  /// Resuelve y retorna los vértices de la región factible.
  ({ResultadoLP resultado, List<Punto> regionFactible, List<Recta> rectas}) resolver(
      ProblemaLP problema) {
    assert(problema.numVariables == 2, 'El método gráfico requiere exactamente 2 variables');

    final rectas = <Recta>[];
    final vertices = <Punto>[];

    // Generar rectas de las restricciones
    for (final r in problema.restricciones) {
      rectas.add(Recta(
        a: r.coeficientes[0],
        b: r.coeficientes[1],
        c: r.rhs,
        nombre: r.nombre,
        tipo: r.tipo,
      ));
    }

    // Agregar ejes (x >= 0, y >= 0) como restricciones implícitas
    rectas.add(Recta(a: 1, b: 0, c: 0, nombre: 'x ≥ 0', tipo: TipoRestriccion.mayorIgual));
    rectas.add(Recta(a: 0, b: 1, c: 0, nombre: 'y ≥ 0', tipo: TipoRestriccion.mayorIgual));

    // Encontrar todas las intersecciones
    for (int i = 0; i < rectas.length; i++) {
      for (int j = i + 1; j < rectas.length; j++) {
        final punto = _interseccion(rectas[i], rectas[j]);
        if (punto != null && _esFactible(punto, rectas)) {
          vertices.add(punto);
        }
      }
    }

    if (vertices.isEmpty) {
      return (
        resultado: ResultadoLP(
          estado: EstadoSolucion.noFactible,
          explicacionSimple: 'No hay región factible. Las restricciones son incompatibles.',
        ),
        regionFactible: [],
        rectas: rectas,
      );
    }

    // Ordenar vértices para dibujar polígono (por ángulo desde centroide)
    final cx = vertices.fold(0.0, (s, p) => s + p.x) / vertices.length;
    final cy = vertices.fold(0.0, (s, p) => s + p.y) / vertices.length;
    vertices.sort((a, b) {
      final aa = atan2(a.y - cy, a.x - cx);
      final ab = atan2(b.y - cy, b.x - cx);
      return aa.compareTo(ab);
    });

    // Evaluar función objetivo en cada vértice
    final c1 = problema.variables[0].coeficienteObjetivo;
    final c2 = problema.variables[1].coeficienteObjetivo;

    Punto mejorV = vertices[0];
    double mejorZ = c1 * mejorV.x + c2 * mejorV.y;

    for (final v in vertices) {
      final z = c1 * v.x + c2 * v.y;
      if (problema.objetivo == TipoObjetivo.maximizar && z > mejorZ) {
        mejorZ = z;
        mejorV = v;
      } else if (problema.objetivo == TipoObjetivo.minimizar && z < mejorZ) {
        mejorZ = z;
        mejorV = v;
      }
    }

    final v1 = problema.variables[0].nombre;
    final v2 = problema.variables[1].nombre;

    return (
      resultado: ResultadoLP(
        estado: EstadoSolucion.optimo,
        valorOptimo: mejorZ,
        valoresVariables: {v1: mejorV.x, v2: mejorV.y},
        explicacionSimple:
            'El punto óptimo está en $v1 = ${mejorV.x.toStringAsFixed(2)}, '
            '$v2 = ${mejorV.y.toStringAsFixed(2)} con Z = ${mejorZ.toStringAsFixed(2)}.',
        explicacionDetallada:
            'Método gráfico: Se encontraron ${vertices.length} vértices factibles.\n'
            'Se evaluó Z = ${c1}·$v1 + ${c2}·$v2 en cada uno:\n'
            '${vertices.map((v) => '  ($v1=${v.x.toStringAsFixed(2)}, $v2=${v.y.toStringAsFixed(2)}) → Z = ${(c1 * v.x + c2 * v.y).toStringAsFixed(2)}').join('\n')}\n'
            '\nÓptimo: ($v1=${mejorV.x.toStringAsFixed(2)}, $v2=${mejorV.y.toStringAsFixed(2)}) → Z = ${mejorZ.toStringAsFixed(2)}',
      ),
      regionFactible: vertices,
      rectas: rectas,
    );
  }

  Punto? _interseccion(Recta r1, Recta r2) {
    final det = r1.a * r2.b - r2.a * r1.b;
    if (det.abs() < 1e-10) return null;
    final x = (r1.c * r2.b - r2.c * r1.b) / det;
    final y = (r1.a * r2.c - r2.a * r1.c) / det;
    if (x < -1e-8 || y < -1e-8) return null;
    return Punto(x < 1e-8 ? 0 : x, y < 1e-8 ? 0 : y);
  }

  bool _esFactible(Punto p, List<Recta> rectas) {
    for (final r in rectas) {
      final val = r.a * p.x + r.b * p.y;
      switch (r.tipo) {
        case TipoRestriccion.menorIgual:
          if (val > r.c + 1e-6) return false;
          break;
        case TipoRestriccion.mayorIgual:
          if (val < r.c - 1e-6) return false;
          break;
        case TipoRestriccion.igual:
          if ((val - r.c).abs() > 1e-6) return false;
          break;
      }
    }
    return true;
  }
}

class Punto {
  final double x;
  final double y;
  Punto(this.x, this.y);
}

class Recta {
  final double a;
  final double b;
  final double c;
  final String nombre;
  final TipoRestriccion tipo;

  Recta({
    required this.a,
    required this.b,
    required this.c,
    required this.nombre,
    required this.tipo,
  });
}
