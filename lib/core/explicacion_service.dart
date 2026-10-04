import 'package:asistente_pl/models/lp_models.dart';

/// Genera explicaciones de dos niveles para los resultados.
class ExplicacionService {
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

    // Agregar interpretación de negocios
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

    // Restricciones activas
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

    // Calcular confianza basada en holguras y sensibilidad
    double confianza = 0.8; // Base
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
      decision =
          productivos.map((e) => '${e.value.toStringAsFixed(0)} ${e.key}').join(', ');
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