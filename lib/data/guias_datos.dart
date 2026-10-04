/// Catálogo de "guías por variable" — sección 9.3 del documento de
/// especificaciones. Se muestran cuando el usuario no sabe cómo obtener
/// un dato, en lenguaje simple y no técnico.
class GuiaDato {
  final String clave;
  final String titulo;
  final String texto;
  final double? valorPorDefecto;
  final String? unidadDefecto;

  const GuiaDato({
    required this.clave,
    required this.titulo,
    required this.texto,
    this.valorPorDefecto,
    this.unidadDefecto,
  });
}

const Map<String, GuiaDato> guiasDatos = {
  'hilo_disponible': GuiaDato(
    clave: 'hilo_disponible',
    titulo: 'Hilo disponible',
    texto:
        'Pésalo en una balanza, o indica cuántos rollos/conos tienes y el '
        'peso aproximado de cada uno (rollos × peso ≈ total). Si no tienes '
        'balanza, usa como referencia el peso indicado en el empaque del '
        'proveedor.',
  ),
  'tiempo_disponible': GuiaDato(
    clave: 'tiempo_disponible',
    titulo: 'Tiempo disponible',
    texto:
        'Multiplica: (N.º de máquinas u operarios) × (horas por turno) × '
        '(días del período). Ej.: 3 telares × 8 horas × 25 días ≈ 600 '
        'horas-máquina.',
  ),
  'demanda_estimada': GuiaDato(
    clave: 'demanda_estimada',
    titulo: 'Demanda estimada',
    texto:
        'Cuenta las unidades vendidas el mes pasado revisando tus cuadernos '
        'de venta o boletas. Si es tu primera vez, dinos un número '
        'aproximado de "cuánto crees que podrías vender": el sistema lo '
        'tratará como estimación y podrás ajustarlo después.',
  ),
  'costo_ruta': GuiaDato(
    clave: 'costo_ruta',
    titulo: 'Costo por ruta',
    texto:
        'Suma combustible + peajes del último viaje que hiciste a ese '
        'destino. Si no lo tienes exacto, un valor aproximado también '
        'sirve; el sistema lo marcará como "pendiente de verificar".',
  ),
  'mermas': GuiaDato(
    clave: 'mermas',
    titulo: 'Mermas o desperdicio de producción',
    texto:
        'Compara el peso de insumo comprado vs. el usado realmente en un '
        'lote reciente. Si no lo sabes, el sistema asumirá 5% de merma '
        '(estándar en confección textil) hasta que lo corrijas.',
    valorPorDefecto: 0.05,
  ),
};
