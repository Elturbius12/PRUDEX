import 'package:asistente_pl/models/lp_models.dart';
import 'package:asistente_pl/models/producto.dart';
import 'package:asistente_pl/models/origen_destino.dart';

/// Genera explicaciones de dos niveles para los resultados.
class ExplicacionService {
  // ===================================================================
  // Métodos estáticos — usados por las tarjetas de resultado de los
  // asistentes de producción y rutas (tarjeta_resultado_produccion.dart,
  // tarjeta_resultado_rutas.dart, tabla_trace.dart).
  // ===================================================================

  /// Redondea a 2 decimales y da formato de texto (sin decimales si no
  /// hacen falta). Devuelve '—' si [valor] es nulo.
  static String redondearTxt(double? valor) {
    if (valor == null) return '—';
    final r = (valor * 100).round() / 100;
    return r == r.roundToDouble() ? r.toInt().toString() : r.toString();
  }

  /// Narrativa en lenguaje simple del resultado de producción.
  static String narrativaProduccion(ResultadoLP resultado, List<Producto> productos) {
    final buf = StringBuffer();
    buf.write('Con tus recursos actuales, la mezcla óptima genera una utilidad de '
        'S/. ${redondearTxt(resultado.z)}. ');
    final activos = <String>[];
    for (var i = 0; i < resultado.nombresVariables.length && i < resultado.x.length; i++) {
      if (resultado.x[i] > 0.01) {
        activos.add('${redondearTxt(resultado.x[i])} de ${resultado.nombresVariables[i]}');
      }
    }
    if (activos.isNotEmpty) {
      buf.write('Te conviene producir ${activos.join(', ')}.');
    } else {
      buf.write('No conviene producir ninguna unidad con los datos actuales.');
    }
    return buf.toString();
  }

  /// Análisis de sensibilidad (holguras de recursos) para producción.
  static String sensibilidadProduccion(ResultadoLP resultado) {
    if (resultado.holguras.isEmpty) {
      return 'No hay información de sensibilidad disponible.';
    }
    final buf = StringBuffer();
    for (final h in resultado.holguras) {
      if (h.etiqueta.isEmpty) continue;
      if (h.holgura.abs() < 0.01) {
        buf.writeln('• ${h.etiqueta}: se usa al 100% (${redondearTxt(h.usado)} de '
            '${redondearTxt(h.rhs)}). Conseguir más de este recurso mejoraría tu resultado.');
      } else {
        buf.writeln('• ${h.etiqueta}: tienes margen (usaste ${redondearTxt(h.usado)} de '
            '${redondearTxt(h.rhs)}, sobran ${redondearTxt(h.holgura)}).');
      }
    }
    final texto = buf.toString().trim();
    return texto.isEmpty ? 'No hay información de sensibilidad disponible.' : texto;
  }

  /// Nombre(s) del recurso que actúa como cuello de botella (holgura ≈ 0).
  static String cuelloBottellaProduccion(ResultadoLP resultado) {
    final activos = resultado.holguras
        .where((h) => h.etiqueta.isNotEmpty && h.holgura.abs() < 0.01)
        .map((h) => h.etiqueta)
        .toList();
    if (activos.isEmpty) return 'ninguno (hay margen en todos tus recursos)';
    return activos.join(', ');
  }

  /// Narrativa en lenguaje simple del resultado de rutas/transporte.
  static String narrativaRutas(
    ResultadoLP resultado,
    List<Origen> origenes,
    List<Destino> destinos,
    String? notaBalance,
  ) {
    final buf = StringBuffer();
    buf.write('El plan de envíos óptimo tiene un costo total de S/. ${redondearTxt(resultado.z)}, '
        'repartiendo la mercadería entre ${origenes.length} origen(es) y ${destinos.length} destino(s). ');
    if (notaBalance != null && notaBalance.isNotEmpty) {
      buf.write('Nota: $notaBalance.');
    }
    return buf.toString();
  }

  /// Análisis de sensibilidad (holguras de oferta por origen) para rutas.
  static String sensibilidadRutas(ResultadoLP resultado, List<Origen> origenes) {
    if (resultado.holguras.isEmpty) {
      return 'No hay información de sensibilidad disponible.';
    }
    final buf = StringBuffer();
    for (final h in resultado.holguras) {
      if (h.etiqueta.isEmpty) continue;
      if (h.holgura.abs() < 0.01) {
        buf.writeln('• ${h.etiqueta}: usa toda su oferta disponible '
            '(${redondearTxt(h.usado)} de ${redondearTxt(h.rhs)}).');
      } else {
        buf.writeln('• ${h.etiqueta}: le queda oferta sin usar '
            '(${redondearTxt(h.holgura)} de ${redondearTxt(h.rhs)}).');
      }
    }
    final texto = buf.toString().trim();
    return texto.isEmpty ? 'No hay información de sensibilidad disponible.' : texto;
  }

  // ===================================================================
  // Métodos de instancia — usados por el flujo de chat original
  // (app_state.dart → resolverModelo / generarRecomendacion).
  // ===================================================================

  /// Explicación simple para el emprendedor (5 segundos).
  String explicacionRapida(ProblemaLP problema, ResultadoLP resultado) {
    if (resultado.estado != EstadoSolucion.optimo) {
      return _explicarEstado(resultado.estado);
    }
    return resultado.explicacionSimple ?? 'Solución encontrada.';
  }

  /// Explicación detallada para quien quiera entender.
  String explicacionCompleta(ProblemaLP problema, ResultadoLP resultado) {
    if (resultado.estado != EstadoSolucion.optimo) {
      return _explicarEstadoDetallado(resultado.estado);
    }

    final buf = StringBuffer();
    buf.writeln(resultado.explicacionDetallada ?? '');
    buf.writeln('\n--- Interpretación para tu negocio ---\n');

    final vals = resultado.valoresVariables;
    final activos = vals.entries.where((e) => e.value > 0.001).toList();
    final inactivos = vals.entries.where((e) => e.value <= 0.001).toList();

    if (activos.isNotEmpty) {
      buf.writeln('Deberías producir/hacer:');
      for (final e in activos) {
        buf.writeln('  • ${e.key}: ${e.value.toStringAsFixed(1)} unidades');
      }
    }

    if (inactivos.isNotEmpty) {
      buf.writeln('\nNo conviene producir:');
      for (final e in inactivos) {
        buf.writeln('  • ${e.key} (no es rentable con las restricciones actuales)');
      }
    }

    if (resultado.preciosSombra != null) {
      final activas = <String>[];
      final holgadas = <String>[];
      for (int i = 0;
          i < resultado.preciosSombra!.length && i < problema.restricciones.length;
          i++) {
        if (resultado.preciosSombra![i].abs() > 0.001) {
          activas.add(problema.restricciones[i].nombre);
        } else {
          holgadas.add(problema.restricciones[i].nombre);
        }
      }
      if (activas.isNotEmpty) {
        buf.writeln('\nRecursos que se usan al máximo (cuellos de botella):');
        for (final a in activas) {
          buf.writeln('  ⚠ $a — conseguir más de este recurso mejoraría tu resultado');
        }
      }
      if (holgadas.isNotEmpty) {
        buf.writeln('\nRecursos con capacidad sobrante:');
        for (final h in holgadas) {
          buf.writeln('  ✅ $h — tienes margen aquí');
        }
      }
    }

    return buf.toString();
  }

  /// Genera recomendación semáforo.
  ({String decision, String impacto, double confianza, String explicacion})
      generarRecomendacion(ProblemaLP problema, ResultadoLP resultado) {
    if (resultado.estado != EstadoSolucion.optimo) {
      return (
        decision: 'Revisar restricciones',
        impacto: 'No se puede calcular',
        confianza: 0.0,
        explicacion: _explicarEstado(resultado.estado),
      );
    }

    final z = resultado.valorOptimo ?? 0;
    final vals = resultado.valoresVariables;
    final productivos = vals.entries.where((e) => e.value > 0.001).toList();

    double confianza = 0.8;
    if (resultado.sensibilidad != null) {
      for (final rango in resultado.sensibilidad!.rangosObjetivo) {
        final amplitud = (rango.limiteSuperior - rango.limiteInferior).abs();
        if (amplitud < rango.valorActual.abs() * 0.1) {
          confianza -= 0.1;
        }
      }
    }
    confianza = confianza.clamp(0.1, 1.0);

    String decision;
    if (productivos.length <= 3) {
      decision = productivos
          .map((e) => '${e.value.toStringAsFixed(0)} ${e.key}')
          .join(', ');
    } else {
      decision = '${productivos.length} productos en mezcla óptima';
    }

    final verbo = problema.objetivo == TipoObjetivo.maximizar ? 'Ganancia' : 'Costo';

    return (
      decision: decision,
      impacto: '$verbo: ${z.toStringAsFixed(2)}',
      confianza: confianza,
      explicacion: explicacionRapida(problema, resultado),
    );
  }

  String _explicarEstado(EstadoSolucion estado) {
    switch (estado) {
      case EstadoSolucion.optimo:
        return 'Se encontró la solución óptima.';
      case EstadoSolucion.noFactible:
      case EstadoSolucion.infactible:
        return 'No hay solución posible. Tus restricciones se contradicen — '
            'revisa si algún límite es demasiado estricto.';
      case EstadoSolucion.noAcotado:
        return 'La solución crece sin límite. Probablemente falta '
            'alguna restricción importante.';
      case EstadoSolucion.multiples:
        return 'Hay varias soluciones igualmente buenas.';
      case EstadoSolucion.enProceso:
        return 'Calculando...';
    }
  }

  String _explicarEstadoDetallado(EstadoSolucion estado) {
    switch (estado) {
      case EstadoSolucion.noFactible:
      case EstadoSolucion.infactible:
        return 'El sistema de restricciones no tiene solución factible.\n\n'
            'Esto significa que es imposible cumplir todas las restricciones al mismo tiempo.\n\n'
            'Posibles causas:\n'
            '  • Restricciones contradictorias\n'
            '  • Límites demasiado estrictos\n'
            '  • Error al ingresar los datos\n\n'
            'Sugerencia: Revisa cada restricción y verifica que tenga sentido.';
      case EstadoSolucion.noAcotado:
        return 'La función objetivo puede crecer (o decrecer) sin límite.\n\n'
            'Esto generalmente indica que falta alguna restricción en el modelo.\n\n'
            'Sugerencia: Verifica que todas las variables tengan algún límite superior.';
      default:
        return _explicarEstado(estado);
    }
  }
}