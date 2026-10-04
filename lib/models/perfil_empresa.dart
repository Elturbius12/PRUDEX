/// Perfil de empresa (onboarding) — sección 9.1 del documento de
/// especificaciones. Ningún campo es obligatorio; sirve como caché de
/// contexto para que el asistente no vuelva a preguntar lo ya conocido.
class PerfilEmpresa {
  String nombre;
  String rubro;
  String anios;
  String trabajadores;
  String maquinas;
  String turnos;
  String notas;

  PerfilEmpresa({
    this.nombre = '',
    this.rubro = '',
    this.anios = '',
    this.trabajadores = '',
    this.maquinas = '',
    this.turnos = '',
    this.notas = '',
  });

  Map<String, dynamic> toJson() => {
        'nombre': nombre,
        'rubro': rubro,
        'anios': anios,
        'trabajadores': trabajadores,
        'maquinas': maquinas,
        'turnos': turnos,
        'notas': notas,
      };

  factory PerfilEmpresa.fromJson(Map<String, dynamic> json) => PerfilEmpresa(
        nombre: json['nombre'] as String? ?? '',
        rubro: json['rubro'] as String? ?? '',
        anios: json['anios'] as String? ?? '',
        trabajadores: json['trabajadores'] as String? ?? '',
        maquinas: json['maquinas'] as String? ?? '',
        turnos: json['turnos'] as String? ?? '',
        notas: json['notas'] as String? ?? '',
      );
}

const List<String> rubrosDisponibles = [
  'Comercio (formal e informal)',
  'Manufactura textil / confecciones',
  'Metalmecánica y orfebrería',
  'Transporte y logística',
  'Servicios financieros',
  'Otro',
];
