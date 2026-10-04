import 'package:flutter/material.dart';
import '../data/guias_datos.dart';
import '../theme/app_theme.dart';

class AyudaScreen extends StatelessWidget {
  const AyudaScreen({super.key});

  static const _comandos = [
    ['"el hilo disponible es 500"', 'Fija el hilo disponible del asistente de producción'],
    ['"el tiempo disponible es 200"', 'Fija el tiempo disponible del asistente de producción'],
    ['"agrega producto chompas utilidad 40 hilo 2 tiempo 1 demanda 150"', 'Agrega un producto nuevo'],
    ['"sube la demanda de chalinas a 180"', 'Ajusta la demanda de un producto existente'],
    ['"quita el producto ponchos"', 'Elimina un producto de la lista'],
    ['"agrega el origen almacén sur con oferta 100"', 'Agrega un origen en el asistente de rutas'],
    ['"agrega el destino puno con demanda 80"', 'Agrega un destino en el asistente de rutas'],
    ['"el costo de almacén sur a puno es 12"', 'Fija el costo de una ruta específica'],
    ['"resuelve" / "calcula"', 'Ejecuta el motor de PL sobre el asistente activo'],
    ['"léeme el resumen"', 'Lee en voz alta el último resultado calculado'],
    ['"explícame en detalle técnico"', 'Cambia al nivel técnico de la explicación'],
    ['"resumen ejecutivo"', 'Vuelve al nivel ejecutivo de la explicación'],
    ['"quiero optimizar producción" / "quiero optimizar rutas"', 'Cambia de asistente'],
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Guías de obtención de datos', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        const SizedBox(height: 6),
        const Text(
          'Si no conoces un dato, el sistema no se detiene: te sugiere cómo conseguirlo o usa '
          'un valor típico del sector, dejando claro que es una aproximación a verificar.',
          style: TextStyle(fontSize: 12.5, color: Colors.grey),
        ),
        const SizedBox(height: 10),
        ...guiasDatos.values.map((g) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(g.titulo, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  Text(g.texto, style: const TextStyle(fontSize: 12.5, height: 1.35)),
                ],
              ),
            )),
        const Divider(height: 28),
        const Text('Comandos de voz que entiende el asistente',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        const SizedBox(height: 8),
        Table(
          border: TableBorder.all(color: Colors.grey.shade300),
          columnWidths: const {0: FlexColumnWidth(1.3), 1: FlexColumnWidth(1)},
          children: [
            const TableRow(
              decoration: BoxDecoration(color: Color(0xFFEEF4FB)),
              children: [_Encabezado('Puedes decir…'), _Encabezado('Qué hace')],
            ),
            for (final c in _comandos) TableRow(children: [_CeldaTexto(c[0]), _CeldaTexto(c[1])]),
          ],
        ),
        const Divider(height: 28),
        const Text('Sobre este prototipo', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppTheme.azulOscuro)),
        const SizedBox(height: 6),
        const Text(
          'Esta app resuelve el modelo de Programación Lineal con un motor Simplex (Big M) '
          'propio, en el propio dispositivo — sin enviar tus datos a ningún servidor. El '
          'reconocimiento y la síntesis de voz usan los motores nativos del dispositivo '
          '(a través de los paquetes speech_to_text y flutter_tts), que en muchos equipos '
          'Android funcionan con soporte offline parcial una vez descargado el paquete de '
          'idioma español. Para una versión de producción a mayor escala se recomienda migrar '
          'a un backend propio con un solver industrial (HiGHS/CBC) y, si se requiere, un '
          'motor de voz más robusto (Whisper) — la lógica de negocio ya está separada en capas '
          'para permitir ese cambio sin rehacer el resto de la app.',
          style: TextStyle(fontSize: 12.5, height: 1.4),
        ),
        const SizedBox(height: 80),
      ],
    );
  }
}

class _Encabezado extends StatelessWidget {
  final String texto;
  const _Encabezado(this.texto);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Text(texto, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
      );
}

class _CeldaTexto extends StatelessWidget {
  final String texto;
  const _CeldaTexto(this.texto);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Text(texto, style: const TextStyle(fontSize: 11.5)),
      );
}
