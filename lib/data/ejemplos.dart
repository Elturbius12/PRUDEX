import '../models/producto.dart';
import '../models/origen_destino.dart';

/// Datos de ejemplo (los mismos usados en el prototipo web de validación),
/// para que un usuario nuevo vea la app funcionando de inmediato con el
/// botón "Cargar ejemplo", antes de meter sus propios datos.
List<Producto> productosEjemplo() => [
      Producto(nombre: 'Chompas', utilidad: 40, hilo: 2, tiempo: 1, demanda: 150),
      Producto(nombre: 'Chalinas', utilidad: 25, hilo: 1, tiempo: 0.5, demanda: 300),
    ];

const double hiloEjemplo = 500;
const double tiempoEjemplo = 200;

List<Origen> origenesEjemplo() => [
      Origen(nombre: 'Almacén Juliaca', oferta: 100),
      Origen(nombre: 'Planta 2', oferta: 150),
    ];

List<Destino> destinosEjemplo() => [
      Destino(nombre: 'Cliente Puno', demanda: 120),
      Destino(nombre: 'Cliente Arequipa', demanda: 130),
    ];

List<List<double>> costosEjemplo() => [
      [4, 6],
      [5, 3],
    ];
