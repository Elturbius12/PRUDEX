import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/perfil_empresa.dart';
import '../state/app_state.dart';

/// Registro de empresa (onboarding) — sección 9.1 del documento. Ningún
/// campo es obligatorio: lo que el usuario llena aquí queda como caché de
/// contexto para que el asistente no vuelva a preguntarlo.
class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  late TextEditingController _nombre, _anios, _trabajadores, _maquinas, _turnos, _notas;
  String _rubro = '';
  bool _inicializado = false;

  @override
  Widget build(BuildContext context) {
    final estado = context.watch<AppState>();
    if (!_inicializado) {
      final p = estado.perfil;
      _nombre = TextEditingController(text: p.nombre);
      _anios = TextEditingController(text: p.anios);
      _trabajadores = TextEditingController(text: p.trabajadores);
      _maquinas = TextEditingController(text: p.maquinas);
      _turnos = TextEditingController(text: p.turnos);
      _notas = TextEditingController(text: p.notas);
      _rubro = p.rubro;
      _inicializado = true;
    }

    void guardar() {
      estado.guardarPerfil(PerfilEmpresa(
        nombre: _nombre.text,
        rubro: _rubro,
        anios: _anios.text,
        trabajadores: _trabajadores.text,
        maquinas: _maquinas.text,
        turnos: _turnos.text,
        notas: _notas.text,
      ));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Ningún campo es obligatorio. Lo que registres aquí se reutiliza automáticamente '
          'en tus próximas consultas para no volver a preguntártelo.',
          style: TextStyle(fontSize: 12.5, color: Colors.grey),
        ),
        const SizedBox(height: 16),
        _campo('Nombre de la empresa / negocio', _nombre, onChanged: (_) => guardar()),
        const SizedBox(height: 10),
        const Text('Rubro', style: TextStyle(fontSize: 12.5, color: Colors.grey)),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          initialValue: _rubro.isEmpty ? null : _rubro,
          decoration: const InputDecoration(isDense: true),
          items: rubrosDisponibles
              .map((r) => DropdownMenuItem(value: r, child: Text(r, style: const TextStyle(fontSize: 13))))
              .toList(),
          onChanged: (v) {
            setState(() => _rubro = v ?? '');
            guardar();
          },
        ),
        const SizedBox(height: 10),
        _campo('Años operando', _anios, teclado: TextInputType.number, onChanged: (_) => guardar()),
        const SizedBox(height: 10),
        _campo('N.º de trabajadores', _trabajadores, teclado: TextInputType.number, onChanged: (_) => guardar()),
        const SizedBox(height: 10),
        _campo('Máquinas / vehículos disponibles', _maquinas,
            sugerencia: 'ej. 3 telares, 2 camionetas', onChanged: (_) => guardar()),
        const SizedBox(height: 10),
        _campo('Turnos de trabajo', _turnos,
            sugerencia: 'ej. 1 turno de 8h, lunes a sábado', onChanged: (_) => guardar()),
        const SizedBox(height: 10),
        const Text('Notas / historial de ventas o producción', style: TextStyle(fontSize: 12.5, color: Colors.grey)),
        const SizedBox(height: 4),
        TextField(
          controller: _notas,
          maxLines: 3,
          decoration: const InputDecoration(isDense: true),
          onChanged: (_) => guardar(),
        ),
        const SizedBox(height: 10),
        const Chip(
          avatar: Icon(Icons.check_circle, size: 16, color: Colors.green),
          label: Text('Perfil guardado en este dispositivo', style: TextStyle(fontSize: 11.5)),
          backgroundColor: Color(0xFFE6F7EC),
        ),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _campo(
    String etiqueta,
    TextEditingController controlador, {
    TextInputType? teclado,
    String? sugerencia,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(etiqueta, style: const TextStyle(fontSize: 12.5, color: Colors.grey)),
        const SizedBox(height: 4),
        TextField(
          controller: controlador,
          keyboardType: teclado,
          decoration: InputDecoration(isDense: true, hintText: sugerencia),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
