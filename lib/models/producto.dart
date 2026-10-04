/// Producto del Asistente de Producción (Caso de uso 1: mezcla óptima de
/// producción textil). Corresponde a la tabla "Variables a considerar
/// (núcleo)" del documento de especificaciones.
class Producto {
  String nombre;
  double utilidad; // utilidad / unidad (S/.)
  double hilo; // hilo / unidad
  double tiempo; // tiempo de producción / unidad (horas)
  double demanda; // demanda estimada (tope superior)
  double demandaMinima; // pedidos/contratos comprometidos (0 = ninguno)

  Producto({
    required this.nombre,
    required this.utilidad,
    required this.hilo,
    required this.tiempo,
    required this.demanda,
    this.demandaMinima = 0,
  });

  factory Producto.vacio(int numero) => Producto(
        nombre: 'Producto $numero',
        utilidad: 0,
        hilo: 0,
        tiempo: 0,
        demanda: 0,
        demandaMinima: 0,
      );

  Map<String, dynamic> toJson() => {
        'nombre': nombre,
        'utilidad': utilidad,
        'hilo': hilo,
        'tiempo': tiempo,
        'demanda': demanda,
        'demandaMinima': demandaMinima,
      };

  factory Producto.fromJson(Map<String, dynamic> json) => Producto(
        nombre: json['nombre'] as String? ?? '',
        utilidad: (json['utilidad'] as num?)?.toDouble() ?? 0,
        hilo: (json['hilo'] as num?)?.toDouble() ?? 0,
        tiempo: (json['tiempo'] as num?)?.toDouble() ?? 0,
        demanda: (json['demanda'] as num?)?.toDouble() ?? 0,
        demandaMinima: (json['demandaMinima'] as num?)?.toDouble() ?? 0,
      );
}
