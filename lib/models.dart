/// Entidades del modelo ER de RappoLink:
/// ROLES, USUARIOS, MATERIAS, GRUPOS, ASIGNACIONES, HORARIOS_ATENCION,
/// CONVERSACIONES, MENSAJES, MENSAJES_PROGRAMADOS.

enum Rol { admin, docente, alumno }

extension RolX on Rol {
  String get nombre {
    switch (this) {
      case Rol.admin:
        return 'Administrador';
      case Rol.docente:
        return 'Docente';
      case Rol.alumno:
        return 'Alumno';
    }
  }
}

class Usuario {
  final String id;
  String nombre;
  String correo;
  String password;
  Rol rol;
  bool activo;
  String? grupo; // solo alumnos (INSCRIPCIONES)

  Usuario({
    required this.id,
    required this.nombre,
    required this.correo,
    required this.password,
    required this.rol,
    this.activo = true,
    this.grupo,
  });

  String get inicial => nombre.isEmpty ? '?' : nombre[0].toUpperCase();
  String get primerNombre => nombre.split(' ').first;
}

class Asignacion {
  final String id;
  final String docenteId;
  final String materia;
  final String grupo;
  Asignacion({
    required this.id,
    required this.docenteId,
    required this.materia,
    required this.grupo,
  });
}

class HorarioDia {
  final String dia;
  String inicio; // "08:00"
  String fin; // "16:00"
  bool activo;
  HorarioDia(this.dia, this.inicio, this.fin, this.activo);
  HorarioDia copy() => HorarioDia(dia, inicio, fin, activo);
}

enum EstadoMensaje { entregado, programado }

class Mensaje {
  final String deId;
  final String texto;
  final DateTime hora;
  EstadoMensaje estado;
  String? etiquetaEntrega; // "Mañana · 08:00"
  Mensaje({
    required this.deId,
    required this.texto,
    required this.hora,
    this.estado = EstadoMensaje.entregado,
    this.etiquetaEntrega,
  });
}

class Conversacion {
  final String id;
  final String alumnoId;
  final String docenteId;
  final String materia;
  final List<Mensaje> mensajes;
  int noLeidosDocente;
  int noLeidosAlumno;
  Conversacion({
    required this.id,
    required this.alumnoId,
    required this.docenteId,
    required this.materia,
    List<Mensaje>? mensajes,
    this.noLeidosDocente = 0,
    this.noLeidosAlumno = 0,
  }) : mensajes = mensajes ?? [];

  Mensaje? get ultimo => mensajes.isEmpty ? null : mensajes.last;
}

class MensajeProgramado {
  final String conversacionId;
  final String texto;
  final DateTime entrega;
  MensajeProgramado(this.conversacionId, this.texto, this.entrega);
}

class Disponibilidad {
  final DateTime fecha;
  final String etiqueta;
  Disponibilidad(this.fecha, this.etiqueta);
}
