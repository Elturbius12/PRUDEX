enum AutorMensaje { usuario, sistema }

class MensajeChat {
  final AutorMensaje autor;
  final String texto;
  final DateTime hora;

  MensajeChat({required this.autor, required this.texto, DateTime? hora})
      : hora = hora ?? DateTime.now();
}

enum NivelExplicacion { ejecutivo, tecnico }
