import 'dart:io';
import 'package:excel/excel.dart' as xl;
import 'package:csv/csv.dart';
import 'package:asistente_pl/models/lp_models.dart';

/// Servicio para importar/exportar datos desde Excel y CSV.
class ExcelService {
  /// Importa un archivo Excel o CSV y detecta la estructura.
  Future<DatosImportados> importar(String filePath) async {
    final ext = filePath.toLowerCase().split('.').last;

    if (ext == 'csv') {
      return _importarCSV(filePath);
    } else if (ext == 'xlsx' || ext == 'xls') {
      return _importarExcel(filePath);
    }

    return DatosImportados(
      encabezados: [],
      filas: [],
      tipoDetectado: TipoDatoDetectado.desconocido,
      mensaje: 'Formato no soportado: .$ext',
    );
  }

  Future<DatosImportados> _importarExcel(String path) async {
    try {
      final bytes = await File(path).readAsBytes();
      final excel = xl.Excel.decodeBytes(bytes);

      final sheet = excel.tables[excel.tables.keys.first]!;
      if (sheet.rows.isEmpty) {
        return DatosImportados(
          encabezados: [],
          filas: [],
          tipoDetectado: TipoDatoDetectado.desconocido,
          mensaje: 'El archivo está vacío',
        );
      }

      final encabezados = sheet.rows.first
          .map((c) => c?.value?.toString() ?? '')
          .toList();

      final filas = <List<String>>[];
      for (int i = 1; i < sheet.rows.length; i++) {
        filas.add(sheet.rows[i]
            .map((c) => c?.value?.toString() ?? '')
            .toList());
      }

      final tipo = _detectarTipo(encabezados, filas);

      return DatosImportados(
        encabezados: encabezados,
        filas: filas,
        tipoDetectado: tipo,
        mensaje: _mensajeTipo(tipo, filas.length),
      );
    } catch (e) {
      return DatosImportados(
        encabezados: [],
        filas: [],
        tipoDetectado: TipoDatoDetectado.desconocido,
        mensaje: 'Error al leer el archivo: $e',
      );
    }
  }

  Future<DatosImportados> _importarCSV(String path) async {
    try {
      final content = await File(path).readAsString();
      final rows = const CsvToListConverter().convert(content);

      if (rows.isEmpty) {
        return DatosImportados(
          encabezados: [],
          filas: [],
          tipoDetectado: TipoDatoDetectado.desconocido,
          mensaje: 'El archivo está vacío',
        );
      }

      final encabezados = rows.first.map((e) => e.toString()).toList();
      final filas = rows.skip(1).map((r) => r.map((e) => e.toString()).toList()).toList();

      final tipo = _detectarTipo(encabezados, filas);

      return DatosImportados(
        encabezados: encabezados,
        filas: filas,
        tipoDetectado: tipo,
        mensaje: _mensajeTipo(tipo, filas.length),
      );
    } catch (e) {
      return DatosImportados(
        encabezados: [],
        filas: [],
        tipoDetectado: TipoDatoDetectado.desconocido,
        mensaje: 'Error al leer CSV: $e',
      );
    }
  }

  /// Detecta el tipo de datos basándose en los encabezados.
  TipoDatoDetectado _detectarTipo(List<String> enc, List<List<String>> filas) {
    final lower = enc.map((e) => e.toLowerCase()).toList();

    // Detectar tabla de transporte
    if (lower.any((e) => e.contains('origen')) && lower.any((e) => e.contains('destino'))) {
      return TipoDatoDetectado.transporte;
    }

    // Detectar modelo LP (coeficientes + restricciones)
    if (lower.any((e) => e.contains('variable') || e.contains('producto')) &&
        lower.any((e) => e.contains('restriccion') || e.contains('recurso') ||
            e.contains('limite') || e.contains('rhs'))) {
      return TipoDatoDetectado.modeloLP;
    }

    // Detectar datos de mercado
    if (lower.any((e) => e.contains('precio') || e.contains('demanda') ||
        e.contains('venta') || e.contains('costo'))) {
      return TipoDatoDetectado.datosMercado;
    }

    // Detectar asignación
    if (lower.any((e) => e.contains('tarea') || e.contains('trabajador') ||
        e.contains('asignacion'))) {
      return TipoDatoDetectado.asignacion;
    }

    return TipoDatoDetectado.tablaGeneral;
  }

  String _mensajeTipo(TipoDatoDetectado tipo, int filas) {
    switch (tipo) {
      case TipoDatoDetectado.modeloLP:
        return 'Detecté un modelo de programación lineal con $filas registros';
      case TipoDatoDetectado.transporte:
        return 'Detecté una tabla de transporte con $filas rutas';
      case TipoDatoDetectado.asignacion:
        return 'Detecté un problema de asignación con $filas opciones';
      case TipoDatoDetectado.datosMercado:
        return 'Detecté datos de mercado con $filas registros';
      case TipoDatoDetectado.tablaGeneral:
        return 'Importé $filas registros. Dime cómo quieres usarlos.';
      case TipoDatoDetectado.desconocido:
        return 'No pude identificar el tipo de datos';
    }
  }

  /// Convierte datos importados a un ProblemaLP.
  ProblemaLP? convertirAModelo(DatosImportados datos) {
    if (datos.tipoDetectado != TipoDatoDetectado.modeloLP) return null;

    try {
      final enc = datos.encabezados;
      final filas = datos.filas;

      // Buscar columnas relevantes
      int? colNombre, colObj;
      final colsRestricciones = <int>[];

      for (int j = 0; j < enc.length; j++) {
        final h = enc[j].toLowerCase();
        if (h.contains('variable') || h.contains('producto') || h.contains('nombre')) {
          colNombre = j;
        } else if (h.contains('ganancia') || h.contains('costo') || h.contains('objetivo') ||
            h.contains('beneficio') || h.contains('precio')) {
          colObj = j;
        } else if (h.contains('restriccion') || h.contains('recurso') || h.contains('limite') ||
            _esNumerico(filas.isNotEmpty ? filas[0][j] : '')) {
          colsRestricciones.add(j);
        }
      }

      if (colNombre == null || colObj == null) return null;

      final variables = <VariableLP>[];
      for (final fila in filas) {
        if (fila[colNombre!].trim().isEmpty) continue;
        variables.add(VariableLP(
          nombre: fila[colNombre].trim(),
          coeficienteObjetivo: double.tryParse(fila[colObj!]) ?? 0,
        ));
      }

      // Las restricciones vendrían en otra hoja o sección
      return ProblemaLP(
        nombre: 'Importado desde Excel',
        objetivo: TipoObjetivo.maximizar,
        variables: variables,
        restricciones: [],
      );
    } catch (_) {
      return null;
    }
  }

  bool _esNumerico(String s) {
    return double.tryParse(s.replaceAll(',', '.')) != null;
  }

  /// Exporta un resultado a CSV.
  String exportarCSV(ResultadoLP resultado, ProblemaLP problema) {
    final rows = <List<dynamic>>[];
    rows.add(['Variable', 'Valor óptimo']);
    for (final e in resultado.valoresVariables.entries) {
      rows.add([e.key, e.value]);
    }
    rows.add([]);
    rows.add(['Valor objetivo', resultado.valorOptimo ?? 0]);

    if (resultado.preciosSombra != null) {
      rows.add([]);
      rows.add(['Restricción', 'Precio sombra']);
      for (int i = 0; i < resultado.preciosSombra!.length; i++) {
        rows.add([
          i < problema.restricciones.length ? problema.restricciones[i].nombre : 'R$i',
          resultado.preciosSombra![i],
        ]);
      }
    }

    return const ListToCsvConverter().convert(rows);
  }
}

enum TipoDatoDetectado {
  modeloLP,
  transporte,
  asignacion,
  datosMercado,
  tablaGeneral,
  desconocido,
}

class DatosImportados {
  final List<String> encabezados;
  final List<List<String>> filas;
  final TipoDatoDetectado tipoDetectado;
  final String mensaje;

  DatosImportados({
    required this.encabezados,
    required this.filas,
    required this.tipoDetectado,
    required this.mensaje,
  });
}
