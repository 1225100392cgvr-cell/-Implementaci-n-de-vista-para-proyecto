import 'package:flutter/material.dart';
import 'models.dart';

/// Modo de horario (solo para la demostración en vivo):
/// auto = usa la hora real; dentro/fuera = fuerza el resultado.
enum ModoHorario { auto, dentro, fuera }

const diasSemana = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes'];

int minutos(String hhmm) {
  final p = hhmm.split(':');
  return int.parse(p[0]) * 60 + int.parse(p[1]);
}

String fmtHora(DateTime d) =>
    '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

/// Estado global (Provider + ChangeNotifier).
class AppState extends ChangeNotifier {
  AppState() {
    _seed();
  }

  final List<Usuario> usuarios = [];
  final List<Asignacion> asignaciones = [];
  final List<String> materias = [];
  final List<String> grupos = ['GSI-41', 'GSI-51', 'GSI-52'];
  final Map<String, List<HorarioDia>> horarios = {};
  final List<Conversacion> conversaciones = [];
  final List<MensajeProgramado> programados = [];

  Usuario? actual;
  ModoHorario modoHorario = ModoHorario.auto;
  int _seq = 100;
  String _id(String p) => '$p${_seq++}';

  // ---------------------------------------------------------------- seed
  List<HorarioDia> _horarioBase() => [
        HorarioDia('Lunes', '08:00', '16:00', true),
        HorarioDia('Martes', '08:00', '16:00', true),
        HorarioDia('Miércoles', '10:00', '15:00', true),
        HorarioDia('Jueves', '08:00', '14:00', true),
        HorarioDia('Viernes', '08:00', '14:00', false),
      ];

  void _seed() {
    usuarios.addAll([
      Usuario(
          id: 'u1',
          nombre: 'Administrador RappoLink',
          correo: 'admin@institucion.edu.mx',
          password: 'admin123',
          rol: Rol.admin),
      Usuario(
          id: 'u2',
          nombre: 'Carlos Ramírez',
          correo: 'carlos@institucion.edu.mx',
          password: 'docente123',
          rol: Rol.docente),
      Usuario(
          id: 'u3',
          nombre: 'Laura Hernández',
          correo: 'laura@institucion.edu.mx',
          password: 'docente123',
          rol: Rol.docente),
      Usuario(
          id: 'u4',
          nombre: 'Jorge Pérez',
          correo: 'jorge@institucion.edu.mx',
          password: 'docente123',
          rol: Rol.docente),
      Usuario(
          id: 'u5',
          nombre: 'Ana Torres',
          correo: 'ana@institucion.edu.mx',
          password: 'docente123',
          rol: Rol.docente),
      Usuario(
          id: 'u6',
          nombre: 'Ángel Méndez',
          correo: 'angel@institucion.edu.mx',
          password: 'alumno123',
          rol: Rol.alumno,
          grupo: 'GSI-51'),
      Usuario(
          id: 'u7',
          nombre: 'Sofía García',
          correo: 'sofia@institucion.edu.mx',
          password: 'alumno123',
          rol: Rol.alumno,
          grupo: 'GSI-51'),
      Usuario(
          id: 'u8',
          nombre: 'Luis Torres',
          correo: 'luis@institucion.edu.mx',
          password: 'alumno123',
          rol: Rol.alumno,
          grupo: 'GSI-41'),
      Usuario(
          id: 'u9',
          nombre: 'Mariana Ruiz',
          correo: 'mariana@institucion.edu.mx',
          password: 'alumno123',
          rol: Rol.alumno,
          grupo: 'GSI-51'),
    ]);

    materias.addAll([
      'Programación III',
      'Programación II',
      'Bases de Datos',
      'Matemáticas',
      'Inglés',
    ]);

    asignaciones.addAll([
      Asignacion(
          id: 'a1', docenteId: 'u2', materia: 'Programación III', grupo: 'GSI-51'),
      Asignacion(
          id: 'a2', docenteId: 'u3', materia: 'Bases de Datos', grupo: 'GSI-51'),
      Asignacion(
          id: 'a3', docenteId: 'u4', materia: 'Matemáticas', grupo: 'GSI-51'),
      Asignacion(id: 'a4', docenteId: 'u5', materia: 'Inglés', grupo: 'GSI-51'),
      Asignacion(
          id: 'a5', docenteId: 'u2', materia: 'Programación II', grupo: 'GSI-41'),
    ]);

    for (final u in usuarios.where((u) => u.rol == Rol.docente)) {
      horarios[u.id] = _horarioBase();
    }

    final now = DateTime.now();
    DateTime h(int m) => now.subtract(Duration(minutes: m));
    conversaciones.addAll([
      Conversacion(
        id: 'c1',
        alumnoId: 'u6',
        docenteId: 'u2',
        materia: 'Programación III',
        noLeidosDocente: 2,
        noLeidosAlumno: 1,
        mensajes: [
          Mensaje(
              deId: 'u2',
              texto: 'Recuerda revisar la actividad 4.',
              hora: h(40)),
          Mensaje(
              deId: 'u6',
              texto: 'Profe, tengo una duda sobre el punto 3.',
              hora: h(20)),
          Mensaje(
              deId: 'u6', texto: 'Tengo una duda con la actividad', hora: h(18)),
        ],
      ),
      Conversacion(
        id: 'c2',
        alumnoId: 'u7',
        docenteId: 'u2',
        materia: 'Programación III',
        mensajes: [
          Mensaje(deId: 'u7', texto: 'Gracias, profesor', hora: h(90)),
        ],
      ),
      Conversacion(
        id: 'c3',
        alumnoId: 'u8',
        docenteId: 'u2',
        materia: 'Programación II',
        noLeidosDocente: 1,
        mensajes: [
          Mensaje(deId: 'u8', texto: '¿Se entrega hoy?', hora: h(130)),
        ],
      ),
    ]);
  }

  // ------------------------------------------------------------- consultas
  Usuario usuario(String id) => usuarios.firstWhere((u) => u.id == id);

  List<Usuario> get docentes =>
      usuarios.where((u) => u.rol == Rol.docente).toList();
  int contar(Rol r) => usuarios.where((u) => u.rol == r).length;

  List<Asignacion> asignacionesDe(String docenteId) =>
      asignaciones.where((a) => a.docenteId == docenteId).toList();

  /// Docentes que ve el alumno: asignaciones del grupo en el que está inscrito.
  List<Asignacion> docentesDeAlumno(Usuario alumno) =>
      asignaciones.where((a) => a.grupo == alumno.grupo).toList();

  List<Conversacion> conversacionesDe(Usuario u) {
    final l = conversaciones
        .where((c) => c.alumnoId == u.id || c.docenteId == u.id)
        .toList();
    l.sort((a, b) {
      final ha = a.ultimo?.hora ?? DateTime(2000);
      final hb = b.ultimo?.hora ?? DateTime(2000);
      return hb.compareTo(ha);
    });
    return l;
  }

  Conversacion conversacion(String id) =>
      conversaciones.firstWhere((c) => c.id == id);

  int pendientesDocente(String docenteId) => conversaciones
      .where((c) => c.docenteId == docenteId)
      .fold(0, (s, c) => s + c.noLeidosDocente);

  int pendientesAlumno(String alumnoId) => conversaciones
      .where((c) => c.alumnoId == alumnoId)
      .fold(0, (s, c) => s + c.noLeidosAlumno);

  // --------------------------------------------------------------- horario
  bool dentroDeHorario(String docenteId) {
    if (modoHorario == ModoHorario.dentro) return true;
    if (modoHorario == ModoHorario.fuera) return false;
    final now = DateTime.now();
    if (now.weekday > 5) return false;
    final h = horarios[docenteId];
    if (h == null) return false;
    final d = h[now.weekday - 1];
    if (!d.activo) return false;
    final m = now.hour * 60 + now.minute;
    return m >= minutos(d.inicio) && m < minutos(d.fin);
  }

  /// Texto corto para mostrar disponibilidad del docente.
  String textoDisponibilidad(String docenteId) {
    if (dentroDeHorario(docenteId)) {
      final now = DateTime.now();
      final h = horarios[docenteId];
      if (modoHorario == ModoHorario.auto && h != null && now.weekday <= 5) {
        return 'Disponible hasta ${h[now.weekday - 1].fin}';
      }
      return 'Disponible ahora';
    }
    return 'Fuera de horario · ${proximaDisponibilidad(docenteId).etiqueta}';
  }

  Disponibilidad proximaDisponibilidad(String docenteId) {
    final now = DateTime.now();
    final h = horarios[docenteId] ?? [];
    if (h.isNotEmpty) {
      for (var i = 0; i < 8; i++) {
        final day = now.add(Duration(days: i));
        if (day.weekday > 5) continue;
        final d = h[day.weekday - 1];
        if (!d.activo) continue;
        final ini = minutos(d.inicio);
        final start =
            DateTime(day.year, day.month, day.day, ini ~/ 60, ini % 60);
        if (start.isAfter(now)) {
          final dia = i == 0
              ? 'Hoy'
              : i == 1
                  ? 'Mañana'
                  : diasSemana[day.weekday - 1];
          return Disponibilidad(start, '$dia · ${d.inicio}');
        }
      }
    }
    final t = now.add(const Duration(days: 1));
    return Disponibilidad(DateTime(t.year, t.month, t.day, 8), 'Mañana · 08:00');
  }

  void guardarHorarios(String docenteId, List<HorarioDia> nuevos) {
    horarios[docenteId] = nuevos.map((e) => e.copy()).toList();
    notifyListeners();
  }

  void setModoHorario(ModoHorario m) {
    modoHorario = m;
    notifyListeners();
  }

  // ----------------------------------------------------------------- auth
  /// Devuelve null si todo está bien, o el mensaje de error.
  String? login(String correo, String pass) {
    Usuario? u;
    for (final x in usuarios) {
      if (x.correo.toLowerCase() == correo.trim().toLowerCase()) u = x;
    }
    if (u == null) return 'No existe una cuenta con ese correo.';
    if (u.password != pass) return 'Contraseña incorrecta.';
    if (!u.activo) return 'Tu cuenta está desactivada. Contacta al administrador.';
    actual = u;
    notifyListeners();
    return null;
  }

  String? registrar({
    required String nombre,
    required String correo,
    required String password,
    required Rol rol,
    String? grupo,
  }) {
    final existe = usuarios
        .any((u) => u.correo.toLowerCase() == correo.trim().toLowerCase());
    if (existe) return 'Ese correo ya está registrado.';
    final u = Usuario(
      id: _id('u'),
      nombre: nombre.trim(),
      correo: correo.trim().toLowerCase(),
      password: password,
      rol: rol,
      grupo: rol == Rol.alumno ? (grupo ?? grupos.first) : null,
    );
    usuarios.add(u);
    if (rol == Rol.docente) horarios[u.id] = _horarioBase();
    actual = u;
    notifyListeners();
    return null;
  }

  void logout() {
    actual = null;
    notifyListeners();
  }

  // ------------------------------------------------ administración (Admin)
  String? crearUsuario({
    required String nombre,
    required String correo,
    required String password,
    required Rol rol,
    String? grupo,
  }) {
    final existe = usuarios
        .any((u) => u.correo.toLowerCase() == correo.trim().toLowerCase());
    if (existe) return 'Ese correo ya está registrado.';
    final u = Usuario(
      id: _id('u'),
      nombre: nombre.trim(),
      correo: correo.trim().toLowerCase(),
      password: password,
      rol: rol,
      grupo: rol == Rol.alumno ? (grupo ?? grupos.first) : null,
    );
    usuarios.add(u);
    if (rol == Rol.docente) horarios[u.id] = _horarioBase();
    notifyListeners();
    return null;
  }

  void cambiarRol(Usuario u, Rol r) {
    u.rol = r;
    if (r == Rol.alumno) u.grupo ??= grupos.first;
    if (r == Rol.docente) horarios.putIfAbsent(u.id, _horarioBase);
    notifyListeners();
  }

  void toggleActivo(Usuario u) {
    u.activo = !u.activo;
    notifyListeners();
  }

  void agregarMateria(String nombre) {
    final n = nombre.trim();
    if (n.isEmpty || materias.contains(n)) return;
    materias.add(n);
    notifyListeners();
  }

  void agregarGrupo(String nombre) {
    final n = nombre.trim().toUpperCase();
    if (n.isEmpty || grupos.contains(n)) return;
    grupos.add(n);
    notifyListeners();
  }

  String? crearAsignacion(String docenteId, String materia, String grupo) {
    final dup = asignaciones.any((a) =>
        a.docenteId == docenteId && a.materia == materia && a.grupo == grupo);
    if (dup) return 'Esa asignación ya existe.';
    asignaciones.add(Asignacion(
        id: _id('a'), docenteId: docenteId, materia: materia, grupo: grupo));
    notifyListeners();
    return null;
  }

  // ------------------------------------------------------------ mensajería
  Conversacion conversacionPara(Usuario alumno, Asignacion a) {
    for (final c in conversaciones) {
      if (c.alumnoId == alumno.id &&
          c.docenteId == a.docenteId &&
          c.materia == a.materia) {
        return c;
      }
    }
    final c = Conversacion(
        id: _id('c'),
        alumnoId: alumno.id,
        docenteId: a.docenteId,
        materia: a.materia);
    conversaciones.add(c);
    notifyListeners();
    return c;
  }

  void marcarLeida(String convId) {
    final c = conversacion(convId);
    if (actual == null) return;
    if (actual!.id == c.docenteId && c.noLeidosDocente > 0) {
      c.noLeidosDocente = 0;
      notifyListeners();
    } else if (actual!.id == c.alumnoId && c.noLeidosAlumno > 0) {
      c.noLeidosAlumno = 0;
      notifyListeners();
    }
  }

  void enviarMensaje(String convId, String texto) {
    final c = conversacion(convId);
    final me = actual!;
    c.mensajes
        .add(Mensaje(deId: me.id, texto: texto.trim(), hora: DateTime.now()));
    if (me.id == c.alumnoId) {
      c.noLeidosDocente++;
    } else {
      c.noLeidosAlumno++;
    }
    notifyListeners();
  }

  void programarMensaje(String convId, String texto, Disponibilidad d) {
    final c = conversacion(convId);
    final me = actual!;
    c.mensajes.add(Mensaje(
      deId: me.id,
      texto: texto.trim(),
      hora: DateTime.now(),
      estado: EstadoMensaje.programado,
      etiquetaEntrega: d.etiqueta,
    ));
    programados.add(MensajeProgramado(convId, texto.trim(), d.fecha));
    notifyListeners();
  }
}
