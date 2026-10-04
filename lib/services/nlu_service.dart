import '../models/mensaje_chat.dart';
import '../state/app_state.dart';

/// Capa de comprensión de lenguaje natural (sección 6 del documento):
/// traduce el texto (venga de voz o de teclado) en una intención
/// estructurada y actúa sobre [AppState]. Implementado aquí con un
/// enfoque de reglas/expresiones regulares — ligero, predecible y sin
/// depender de una API externa de pago — con una capa de validación
/// implícita (si nada coincide, se responde pidiendo reformular en vez
/// de arriesgar una acción incorrecta), tal como recomienda el documento.
class NluService {
  static String _normalizar(String texto) {
    var s = texto.toLowerCase();
    const acentos = {
      'á': 'a', 'é': 'e', 'í': 'i', 'ó': 'o', 'ú': 'u', 'ü': 'u',
    };
    acentos.forEach((k, v) => s = s.replaceAll(k, v));
    s = s.replaceAll(RegExp(r'[^a-z0-9ñ.,\s]'), ' ');
    s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
    return s;
  }

  static String _num(String crudo) => crudo.replaceAll(',', '.');

  static String _capitalizar(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  /// Interpreta [textoOriginal] y actúa sobre [estado]. Devuelve el texto
  /// de respuesta del asistente (se agrega al chat y se lee en voz alta
  /// desde AppState.procesarComandoTexto).
  static String procesar(String textoOriginal, AppState estado) {
    final t = _normalizar(textoOriginal);
    RegExpMatch? m;

    // ---- Navegación entre asistentes ----
    if (RegExp(r'produccion|chompa|chalina|textil').hasMatch(t) &&
        RegExp(r'quiero|optimizar|activa|abre|ir a|necesito').hasMatch(t)) {
      estado.pedirNavegacion(2);
      return 'Listo, abrí el asistente de producción textil. Dime tu hilo y tiempo '
          'disponibles, o agrega productos.';
    }
    if (RegExp(r'ruta|distribu|transporte|reparto|entrega').hasMatch(t) &&
        RegExp(r'quiero|optimizar|activa|abre|ir a|necesito').hasMatch(t)) {
      estado.pedirNavegacion(3);
      return 'Listo, abrí el asistente de rutas y distribución. Dime tus orígenes, '
          'destinos y costos.';
    }

    // ---- Producción: hilo / tiempo disponibles ----
    m = RegExp(r'hilo (?:disponible|que tengo|es)\s*(?:de|es)?\s*(-?\d+(?:[.,]\d+)?)').firstMatch(t);
    if (m != null) {
      final val = double.parse(_num(m.group(1)!));
      estado.setHiloDisponible(val);
      estado.pedirNavegacion(2);
      return 'Anotado: hilo disponible = ${_txt(val)}.';
    }
    m = RegExp(r'tiempo (?:disponible|que tengo|es)\s*(?:de|es)?\s*(-?\d+(?:[.,]\d+)?)').firstMatch(t);
    if (m != null) {
      final val = double.parse(_num(m.group(1)!));
      estado.setTiempoDisponible(val);
      estado.pedirNavegacion(2);
      return 'Anotado: tiempo disponible = ${_txt(val)} horas.';
    }

    // ---- Producción: agregar / quitar / ajustar producto ----
    m = RegExp(r'agrega(?:r)? producto ([a-z ]+?) utilidad (\d+(?:[.,]\d+)?) hilo (\d+(?:[.,]\d+)?) '
            r'tiempo (\d+(?:[.,]\d+)?) demanda (\d+(?:[.,]\d+)?)')
        .firstMatch(t);
    if (m != null) {
      final nombre = _capitalizar(m.group(1)!.trim());
      estado.agregarProducto();
      final idx = estado.productos.length - 1;
      estado.actualizarProductoCampo(idx, 'nombre', nombre);
      estado.actualizarProductoCampo(idx, 'utilidad', _num(m.group(2)!));
      estado.actualizarProductoCampo(idx, 'hilo', _num(m.group(3)!));
      estado.actualizarProductoCampo(idx, 'tiempo', _num(m.group(4)!));
      estado.actualizarProductoCampo(idx, 'demanda', _num(m.group(5)!));
      estado.pedirNavegacion(2);
      return 'Producto "$nombre" agregado.';
    }
    m = RegExp(r'(?:sube|ajusta|cambia|pon)(?:le)? (?:la )?demanda de ([a-z ]+?) a (\d+(?:[.,]\d+)?)')
        .firstMatch(t);
    if (m != null) {
      final nombreBuscado = m.group(1)!.trim();
      final idx = estado.productos.indexWhere((p) {
        final n = _normalizar(p.nombre);
        return n.contains(nombreBuscado) || nombreBuscado.contains(n);
      });
      if (idx != -1) {
        estado.actualizarProductoCampo(idx, 'demanda', _num(m.group(2)!));
        estado.pedirNavegacion(2);
        return 'Demanda de "${estado.productos[idx].nombre}" actualizada a ${_txt(double.parse(_num(m.group(2)!)))}.';
      }
    }
    m = RegExp(r'(?:quita|elimina|borra)(?:r)? (?:el )?producto ([a-z ]+)').firstMatch(t);
    if (m != null) {
      final nombreBuscado = m.group(1)!.trim();
      final idx = estado.productos.indexWhere((p) => _normalizar(p.nombre).contains(nombreBuscado));
      if (idx != -1) {
        final nombre = estado.productos[idx].nombre;
        estado.quitarProducto(idx);
        return 'Quité "$nombre" de la lista de productos.';
      }
    }

    // ---- Rutas: agregar origen / destino / costo ----
    m = RegExp(r'agrega(?:r)? (?:el )?origen ([a-z0-9 ]+?) (?:con )?oferta (\d+(?:[.,]\d+)?)').firstMatch(t);
    if (m != null) {
      final nombre = _capitalizar(m.group(1)!.trim());
      estado.agregarOrigen();
      final idx = estado.origenes.length - 1;
      estado.actualizarOrigenCampo(idx, 'nombre', nombre);
      estado.actualizarOrigenCampo(idx, 'oferta', _num(m.group(2)!));
      estado.pedirNavegacion(3);
      return 'Origen "$nombre" agregado con oferta ${m.group(2)}.';
    }
    m = RegExp(r'agrega(?:r)? (?:el )?destino ([a-z0-9 ]+?) (?:con )?demanda (\d+(?:[.,]\d+)?)').firstMatch(t);
    if (m != null) {
      final nombre = _capitalizar(m.group(1)!.trim());
      estado.agregarDestino();
      final idx = estado.destinos.length - 1;
      estado.actualizarDestinoCampo(idx, 'nombre', nombre);
      estado.actualizarDestinoCampo(idx, 'demanda', _num(m.group(2)!));
      estado.pedirNavegacion(3);
      return 'Destino "$nombre" agregado con demanda ${m.group(2)}.';
    }
    m = RegExp(r'(?:quita|elimina|borra)(?:r)? (?:el )?origen ([a-z0-9 ]+)').firstMatch(t);
    if (m != null) {
      final nombreBuscado = m.group(1)!.trim();
      final idx = estado.origenes.indexWhere((o) => _normalizar(o.nombre).contains(nombreBuscado));
      if (idx != -1) {
        final nombre = estado.origenes[idx].nombre;
        estado.quitarOrigen(idx);
        return 'Quité el origen "$nombre".';
      }
    }
    m = RegExp(r'(?:quita|elimina|borra)(?:r)? (?:el )?destino ([a-z0-9 ]+)').firstMatch(t);
    if (m != null) {
      final nombreBuscado = m.group(1)!.trim();
      final idx = estado.destinos.indexWhere((d) => _normalizar(d.nombre).contains(nombreBuscado));
      if (idx != -1) {
        final nombre = estado.destinos[idx].nombre;
        estado.quitarDestino(idx);
        return 'Quité el destino "$nombre".';
      }
    }
    m = RegExp(r'costo (?:de|desde) ([a-z0-9 ]+?) a ([a-z0-9 ]+?) es (\d+(?:[.,]\d+)?)').firstMatch(t);
    if (m != null) {
      final nombreOrigen = m.group(1)!.trim();
      final nombreDestino = m.group(2)!.trim();
      final io = estado.origenes.indexWhere((o) => _normalizar(o.nombre).contains(nombreOrigen) || nombreOrigen.contains(_normalizar(o.nombre)));
      final id = estado.destinos.indexWhere((d) => _normalizar(d.nombre).contains(nombreDestino) || nombreDestino.contains(_normalizar(d.nombre)));
      if (io != -1 && id != -1) {
        estado.actualizarCosto(io, id, _num(m.group(3)!));
        estado.pedirNavegacion(3);
        return 'Costo de "${estado.origenes[io].nombre}" a "${estado.destinos[id].nombre}" = ${m.group(3)}.';
      }
    }

    // ---- Resolver / calcular (usa la pestaña activa) ----
    if (RegExp(r'^(resuelve|resolver|calcula|calcular|dame el resultado|optimiza)').hasMatch(t)) {
      if (estado.pestanaActual == 3) {
        estado.resolverRutas();
      } else {
        estado.pedirNavegacion(2);
        estado.resolverProduccion();
      }
      return 'Listo, calculé el resultado. Puedes verlo en pantalla, o decirme "léeme el resumen".';
    }

    // ---- Leer el resumen en voz alta ----
    if (RegExp(r'lee(?:me)? el resumen|leeme el resultado|escuchalo|escucha el resumen').hasMatch(t)) {
      final resumen = estado.pestanaActual == 3 ? estado.resumenHabladoRutas : estado.resumenHabladoProduccion;
      if (resumen == null) {
        return 'Todavía no he resuelto nada en este asistente. Dime "resuelve" primero.';
      }
      return resumen;
    }

    // ---- Nivel de explicación ----
    if (RegExp(r'tecnic|detalle tecnico|a fondo|paso a paso').hasMatch(t)) {
      estado.cambiarNivelExplicacion(NivelExplicacion.tecnico);
      return 'Mostrando el nivel técnico de la explicación.';
    }
    if (RegExp(r'ejecutivo|resumen simple|en simple').hasMatch(t)) {
      estado.cambiarNivelExplicacion(NivelExplicacion.ejecutivo);
      return 'Mostrando el resumen ejecutivo.';
    }

    // ---- Saludo / ayuda ----
    if (RegExp(r'^(hola|buenas|ayuda|que puedes hacer)').hasMatch(t)) {
      return 'Hola, puedo ayudarte a decidir qué producir o cómo repartir tu mercadería. '
          'Dime, por ejemplo: "el hilo disponible es 500", o "resuelve".';
    }

    return 'No estoy seguro de haber entendido ese comando. Puedes escribirlo distinto, '
        'o revisar la pestaña "Ayuda" para ver ejemplos de comandos.';
  }

  static String _txt(double n) {
    final r = (n * 100).round() / 100;
    return r == r.roundToDouble() ? r.toInt().toString() : r.toString();
  }
}
