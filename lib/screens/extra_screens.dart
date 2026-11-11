import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets.dart';
import 'chat_screens.dart';

/// Chip de filtro reutilizable.
class _Filtro extends StatelessWidget {
  final String texto;
  final bool activo;
  final VoidCallback onTap;
  const _Filtro(this.texto, this.activo, this.onTap);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          label: Text(texto),
          selected: activo,
          onSelected: (_) => onTap(),
          showCheckmark: false,
          selectedColor: RL.primary,
          labelStyle: TextStyle(
              color: activo ? Colors.white : RL.text2,
              fontWeight: FontWeight.w600),
        ),
      );
}

Widget _filaFiltros(List<Widget> chips) => SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
        children: chips,
      ),
    );

// ============================================================ INSCRIPCIONES
class InscripcionesScreen extends StatefulWidget {
  const InscripcionesScreen({super.key});
  @override
  State<InscripcionesScreen> createState() => _InscripcionesScreenState();
}

class _InscripcionesScreenState extends State<InscripcionesScreen> {
  String _grupo = 'Todos';
  String _estado = 'Todos';

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final lista = s.inscripciones.where((i) {
      final okG = _grupo == 'Todos' || i.grupo == _grupo;
      final okE = _estado == 'Todos' || i.estado.nombre == _estado;
      return okG && okE;
    }).toList()
      ..sort((a, b) => b.fecha.compareTo(a.fecha));

    return Scaffold(
      appBar: AppBar(title: const Text('Inscripciones')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => const NuevaInscripcionScreen())),
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Inscribir'),
      ),
      body: Column(children: [
        _filaFiltros([
          for (final g in ['Todos', ...s.grupos])
            _Filtro(g, _grupo == g, () => setState(() => _grupo = g)),
        ]),
        _filaFiltros([
          for (final e in ['Todos', 'Activa', 'Baja'])
            _Filtro(e, _estado == e, () => setState(() => _estado = e)),
        ]),
        Expanded(
          child: lista.isEmpty
              ? const EmptyState(
                  icon: Icons.how_to_reg_outlined,
                  title: 'No hay inscripciones',
                  subtitle: 'Prueba con otro grupo o estado.')
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                  children: [
                    for (final i in lista) _InscripcionCard(i),
                  ],
                ),
        ),
      ]),
    );
  }
}

class _InscripcionCard extends StatelessWidget {
  final Inscripcion i;
  const _InscripcionCard(this.i);
  @override
  Widget build(BuildContext context) {
    final s = context.read<AppState>();
    final a = s.usuario(i.alumnoId);
    final activa = i.estado == EstadoInscripcion.activa;
    return RLCard(
      child: Row(children: [
        Avatar(a.inicial),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(a.nombre,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, color: RL.text)),
              const SizedBox(height: 2),
              Text('Grupo ${i.grupo} · ${fmtFecha(i.fecha)}',
                  style: const TextStyle(color: RL.muted, fontSize: 12)),
            ],
          ),
        ),
        Pill(i.estado.nombre,
            color: activa ? RL.green : RL.red,
            bg: activa ? RL.greenSoft : RL.redSoft),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: RL.muted),
          onSelected: (v) => s.cambiarEstadoInscripcion(
              i, v == 'alta' ? EstadoInscripcion.activa : EstadoInscripcion.baja),
          itemBuilder: (_) => [
            if (!activa)
              const PopupMenuItem(value: 'alta', child: Text('Reactivar')),
            if (activa)
              const PopupMenuItem(value: 'baja', child: Text('Retirar alumno')),
          ],
        ),
      ]),
    );
  }
}

class NuevaInscripcionScreen extends StatefulWidget {
  const NuevaInscripcionScreen({super.key});
  @override
  State<NuevaInscripcionScreen> createState() => _NuevaInscripcionScreenState();
}

class _NuevaInscripcionScreenState extends State<NuevaInscripcionScreen> {
  String? _alumno;
  String? _grupo;
  DateTime _fecha = DateTime.now();
  EstadoInscripcion _estado = EstadoInscripcion.activa;
  String? _error;

  Future<void> _elegirFecha() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (d != null) setState(() => _fecha = d);
  }

  void _guardar() {
    if (_alumno == null || _grupo == null) {
      setState(() => _error = 'Selecciona el alumno y el grupo.');
      return;
    }
    final err =
        context.read<AppState>().inscribir(_alumno!, _grupo!, _fecha, _estado);
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    snack(context, 'Alumno inscrito');
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(title: const Text('Nueva inscripción')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          DropdownButtonFormField<String>(
            value: _alumno,
            hint: const Text('Selecciona un alumno'),
            items: s.alumnos
                .map((a) => DropdownMenuItem(value: a.id, child: Text(a.nombre)))
                .toList(),
            onChanged: (v) => setState(() => _alumno = v),
            decoration: const InputDecoration(labelText: 'Alumno'),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            value: _grupo,
            hint: const Text('Selecciona un grupo'),
            items: s.grupos
                .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                .toList(),
            onChanged: (v) => setState(() => _grupo = v),
            decoration: const InputDecoration(labelText: 'Grupo'),
          ),
          const SizedBox(height: 14),
          InkWell(
            onTap: _elegirFecha,
            child: InputDecorator(
              decoration: const InputDecoration(
                  labelText: 'Fecha de inscripción',
                  suffixIcon: Icon(Icons.calendar_today, size: 20)),
              child: Text(fmtFecha(_fecha)),
            ),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<EstadoInscripcion>(
            value: _estado,
            items: EstadoInscripcion.values
                .map((e) => DropdownMenuItem(value: e, child: Text(e.nombre)))
                .toList(),
            onChanged: (v) => setState(() => _estado = v ?? _estado),
            decoration: const InputDecoration(labelText: 'Estado'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: RL.red)),
          ],
          const SizedBox(height: 24),
          FilledButton(onPressed: _guardar, child: const Text('INSCRIBIR')),
        ],
      ),
    );
  }
}

// ===================================================== MENSAJES PROGRAMADOS
class ProgramadosScreen extends StatefulWidget {
  const ProgramadosScreen({super.key});
  @override
  State<ProgramadosScreen> createState() => _ProgramadosScreenState();
}

class _ProgramadosScreenState extends State<ProgramadosScreen> {
  EstadoProgramado? _estado; // null = todos

  Future<void> _editar(BuildContext context, MensajeProgramado p) async {
    final c = TextEditingController(text: p.texto);
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Editar mensaje'),
        content: TextField(
            controller: c,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Mensaje')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size(100, 44)),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('GUARDAR')),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      context.read<AppState>().editarProgramado(p, c.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final me = s.actual!;
    final lista = s
        .programadosDe(me)
        .where((p) => _estado == null || p.estado == _estado)
        .toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Mensajes programados')),
      body: Column(children: [
        _filaFiltros([
          _Filtro('Todos', _estado == null, () => setState(() => _estado = null)),
          for (final e in EstadoProgramado.values)
            _Filtro(e.nombre, _estado == e, () => setState(() => _estado = e)),
        ]),
        Expanded(
          child: lista.isEmpty
              ? const EmptyState(
                  icon: Icons.schedule_send_outlined,
                  title: 'Sin mensajes programados',
                  subtitle:
                      'Cuando escribas fuera del horario del docente, el mensaje aparecerá aquí.')
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    for (final p in lista)
                      _ProgramadoCard(
                          p: p,
                          onEditar: () => _editar(context, p),
                          onCancelar: () => s.cancelarProgramado(p)),
                  ],
                ),
        ),
      ]),
    );
  }
}

class _ProgramadoCard extends StatelessWidget {
  final MensajeProgramado p;
  final VoidCallback onEditar;
  final VoidCallback onCancelar;
  const _ProgramadoCard(
      {required this.p, required this.onEditar, required this.onCancelar});

  @override
  Widget build(BuildContext context) {
    final s = context.read<AppState>();
    final me = s.actual!;
    final c = s.conversacion(p.conversacionId);
    final otro = s.usuario(me.id == c.docenteId ? c.alumnoId : c.docenteId);
    final (Color col, Color bg) = switch (p.estado) {
      EstadoProgramado.pendiente => (RL.amber, RL.amberSoft),
      EstadoProgramado.enviado => (RL.green, RL.greenSoft),
      EstadoProgramado.cancelado => (RL.red, RL.redSoft),
    };
    return RLCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: Text('Para: ${otro.nombre}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, color: RL.text)),
            ),
            Pill(p.estado.nombre, color: col, bg: bg),
          ]),
          const SizedBox(height: 2),
          Text(c.materia,
              style: const TextStyle(
                  color: RL.primary, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('“${p.texto}”',
              style: const TextStyle(
                  color: RL.text2, fontStyle: FontStyle.italic)),
          const SizedBox(height: 8),
          Row(children: [
            const Icon(Icons.event, size: 16, color: RL.muted),
            const SizedBox(width: 6),
            Text('${fmtFecha(p.entrega)} · ${fmtHora(p.entrega)}',
                style: const TextStyle(color: RL.muted, fontSize: 12)),
            const Spacer(),
            if (p.estado == EstadoProgramado.pendiente) ...[
              TextButton(onPressed: onEditar, child: const Text('Editar')),
              TextButton(
                  onPressed: onCancelar,
                  style: TextButton.styleFrom(foregroundColor: RL.red),
                  child: const Text('Cancelar')),
            ],
          ]),
        ],
      ),
    );
  }
}

// ================================================================== AVISOS
class AvisosScreen extends StatelessWidget {
  const AvisosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final me = s.actual!;
    final lista = s.avisosDe(me);
    return Scaffold(
      appBar: AppBar(title: const Text('Notificaciones')),
      body: lista.isEmpty
          ? const EmptyState(
              icon: Icons.notifications_none,
              title: 'No tienes avisos',
              subtitle: 'Aquí aparecerán los mensajes nuevos.')
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (final a in lista)
                  _AvisoCard(a, leido: s.avisosLeidos.contains(a.id)),
              ],
            ),
    );
  }
}

class _AvisoCard extends StatelessWidget {
  final Aviso a;
  final bool leido;
  const _AvisoCard(this.a, {required this.leido});
  @override
  Widget build(BuildContext context) {
    final s = context.read<AppState>();
    return RLCard(
      color: leido ? Colors.white : RL.soft,
      onTap: () {
        s.marcarAviso(a.id);
        Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => ChatScreen(convId: a.convId)));
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                color: a.programado ? RL.amberSoft : RL.violetSoft,
                borderRadius: BorderRadius.circular(12)),
            child: Icon(a.programado ? Icons.schedule_send : Icons.chat_bubble,
                color: a.programado ? RL.amber : RL.violet, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(a.titulo,
                    style: TextStyle(
                        fontWeight: leido ? FontWeight.w600 : FontWeight.w800,
                        color: RL.text)),
                const SizedBox(height: 2),
                Text(a.detalle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: RL.muted, fontSize: 12)),
                const SizedBox(height: 4),
                Text('${fmtFecha(a.fecha)} · ${fmtHora(a.fecha)}',
                    style: const TextStyle(color: RL.muted, fontSize: 11)),
              ],
            ),
          ),
          if (!leido)
            Container(
              width: 10,
              height: 10,
              margin: const EdgeInsets.only(top: 4),
              decoration:
                  const BoxDecoration(color: RL.primary, shape: BoxShape.circle),
            )
          else
            TextButton(onPressed: null, child: const Text('Leído')),
        ],
      ),
    );
  }
}

/// Campana con contador para el encabezado.
class CampanaAvisos extends StatelessWidget {
  const CampanaAvisos({super.key});
  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final n = s.avisosSinLeer(s.actual!);
    return IconButton(
      tooltip: 'Notificaciones',
      onPressed: () => Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => const AvisosScreen())),
      icon: Badge(
        isLabelVisible: n > 0,
        label: Text('$n'),
        child: const Icon(Icons.notifications_outlined, color: RL.text),
      ),
    );
  }
}

// ======================================= HORARIOS DE MIS DOCENTES (ALUMNO)
class HorariosDocentesScreen extends StatelessWidget {
  const HorariosDocentesScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final me = s.actual!;
    final asigs = s.docentesDeAlumno(me);
    final vistos = <String>{};
    return Scaffold(
      appBar: AppBar(title: const Text('Horarios de atención')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final a in asigs)
            if (vistos.add(a.docenteId))
              _HorarioDocenteCard(docenteId: a.docenteId, materia: a.materia),
        ],
      ),
    );
  }
}

class _HorarioDocenteCard extends StatelessWidget {
  final String docenteId;
  final String materia;
  const _HorarioDocenteCard({required this.docenteId, required this.materia});
  @override
  Widget build(BuildContext context) {
    final s = context.read<AppState>();
    final d = s.usuario(docenteId);
    final dentro = s.dentroDeHorario(docenteId);
    final h = s.horarios[docenteId] ?? [];
    return RLCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Avatar(d.inicial, size: 38),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(d.nombre,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, color: RL.text)),
                  Text(materia,
                      style: const TextStyle(color: RL.muted, fontSize: 12)),
                ],
              ),
            ),
            Pill(dentro ? 'Disponible' : 'Fuera de horario',
                color: dentro ? RL.green : RL.amber,
                bg: dentro ? RL.greenSoft : RL.amberSoft),
          ]),
          const SizedBox(height: 10),
          for (final dia in h)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(children: [
                SizedBox(
                    width: 90,
                    child: Text(dia.dia,
                        style: const TextStyle(
                            color: RL.text2, fontWeight: FontWeight.w600))),
                Expanded(
                  child: Text(
                      dia.activo ? '${dia.inicio} – ${dia.fin}' : 'No disponible',
                      style: TextStyle(
                          color: dia.activo ? RL.text : RL.muted, fontSize: 13)),
                ),
                Text(dia.activo ? 'Activo' : 'Inactivo',
                    style: TextStyle(
                        color: dia.activo ? RL.green : RL.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ]),
            ),
        ],
      ),
    );
  }
}
