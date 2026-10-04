/// Modelos del Asistente de Rutas (Caso de uso 2: transporte/distribución).
library;

class Origen {
  String nombre;
  double oferta;

  Origen({required this.nombre, required this.oferta});

  factory Origen.vacio(int numero) => Origen(nombre: 'Origen $numero', oferta: 0);

  Map<String, dynamic> toJson() => {'nombre': nombre, 'oferta': oferta};

  factory Origen.fromJson(Map<String, dynamic> json) => Origen(
        nombre: json['nombre'] as String? ?? '',
        oferta: (json['oferta'] as num?)?.toDouble() ?? 0,
      );
}

class Destino {
  String nombre;
  double demanda;

  Destino({required this.nombre, required this.demanda});

  factory Destino.vacio(int numero) => Destino(nombre: 'Destino $numero', demanda: 0);

  Map<String, dynamic> toJson() => {'nombre': nombre, 'demanda': demanda};

  factory Destino.fromJson(Map<String, dynamic> json) => Destino(
        nombre: json['nombre'] as String? ?? '',
        demanda: (json['demanda'] as num?)?.toDouble() ?? 0,
      );
}
