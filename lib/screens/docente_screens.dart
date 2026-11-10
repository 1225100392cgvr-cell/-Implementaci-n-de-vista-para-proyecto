import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets.dart';
import 'chat_screens.dart';
import 'perfil_screen.dart';

// ====================================================================== SHELL
class DocenteShell extends StatefulWidget {
  const DocenteShell({super.key});
  @override
  State<DocenteShell> createState() => _DocenteShellState();
}

class _DocenteShellState extends State<DocenteShell> {
  int _i = 0;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final pend = s.pendientesDocente(s.actual!.id);
    return Scaffold(
      body: IndexedStack(index: _i, children: [
        DocenteHome(onGo: (n) => setState(() => _i = n)),
        const ChatsScreen(),
        const HorarioScreen(),
        const PerfilScreen(),
      ]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _i,
        onDestinationSelected: (n) => setState(() => _i = n),
        destinations: [
          const NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Inicio'),
          NavigationDestination(
              icon: Badge(
                  isLabelVisible: pend > 0,
                  label: Text('$pend'),
                  child: const Icon(Icons.chat_bubble_outline)),
              selectedIcon: const Icon(Icons.chat_bubble),
              label: 'Chats'),
          const NavigationDestination(
              icon: Icon(Icons.schedule),
              selectedIcon: Icon(Icons.schedule),
              label: 'Horario'),
          const NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Perfil'),
        ],
      ),
    );
  }
}

// ================================================================= DASHBOARD
class DocenteHome extends StatelessWidget {
  final ValueChanged<int> onGo;
  const DocenteHome({super.key, required this.onGo});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final me = s.actual!;
    final dentro = s.dentroDeHorario(me.id);
    final asigs = s.asignacionesDe(me.id);
    final pend = s.pendientesDocente(me.id);

    return Column(
      children: [
        TabHeader(
          title: 'Hola, ${me.primerNombre} 👋',
          subtitle: 'Docente · ${s.asignacionesDe(me.id).length} asignaciones',
          trailing: const Pill('Rol: Docente'),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              HorarioBanner(
                dentro: dentro,
                titulo: dentro ? 'Dentro de horario' : 'Fuera de horario',
                detalle: s.textoDisponibilidad(me.id),
              ),
              const SizedBox(height: 8),
              const SectionLabel('Mis asignaciones'),
              if (asigs.isEmpty)
                const RLCard(
                    child: Text('Aún no tienes materias asignadas.',
                        style: TextStyle(color: RL.muted)))
              else
                for (final a in asigs)
                  RLCard(
                    child: Row(children: [
                      const Avatar('P'),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(a.materia,
                            style: const TextStyle(
                                fontWeight: FontWeight.w800, color: RL.text)),
                      ),
                      Pill(a.grupo),
                    ]),
                  ),
              const SectionLabel('Accesos rápidos'),
              Row(children: [
                Expanded(
                  child: _Quick(
                    icon: Icons.chat_bubble,
                    titulo: 'Chats',
                    detalle: '$pend pendientes',
                    onTap: () => onGo(1),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _Quick(
                    icon: Icons.schedule,
                    titulo: 'Horario',
                    detalle: 'Editar atención',
                    color: RL.violet,
                    bg: RL.violetSoft,
                    onTap: () => onGo(2),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ],
    );
  }
}

class _Quick extends StatelessWidget {
  final IconData icon;
  final String titulo;
  final String detalle;
  final VoidCallback onTap;
  final Color color;
  final Color bg;
  const _Quick(
      {required this.icon,
      required this.titulo,
      required this.detalle,
      required this.onTap,
      this.color = RL.primary,
      this.bg = RL.soft});
  @override
  Widget build(BuildContext context) => RLCard(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                  color: bg, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color),
            ),
            const SizedBox(height: 10),
            Text(titulo,
                style: const TextStyle(
                    fontWeight: FontWeight.w800, color: RL.text)),
            Text(detalle,
                style: const TextStyle(color: RL.muted, fontSize: 12)),
          ],
        ),
      );
}

// ================================================ FORMULARIO: HORARIO ATENCIÓN
class HorarioScreen extends StatefulWidget {
  const HorarioScreen({super.key});
  @override
  State<HorarioScreen> createState() => _HorarioScreenState();
}

class _HorarioScreenState extends State<HorarioScreen> {
  late List<HorarioDia> _h;

  @override
  void initState() {
    super.initState();
    final s = context.read<AppState>();
    _h = s.horarios[s.actual!.id]!.map((e) => e.copy()).toList();
  }

  Future<void> _pick(HorarioDia d, bool inicio) async {
    final actual = inicio ? d.inicio : d.fin;
    final p = actual.split(':');
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1])),
    );
    if (t == null) return;
    final v =
        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    setState(() => inicio ? d.inicio = v : d.fin = v);
  }

  void _guardar() {
    for (final d in _h) {
      if (d.activo && minutos(d.fin) <= minutos(d.inicio)) {
        snack(context, '${d.dia}: la hora de fin debe ser mayor al inicio',
            error: true);
        return;
      }
    }
    final s = context.read<AppState>();
    s.guardarHorarios(s.actual!.id, _h);
    snack(context, 'Horario guardado correctamente');
  }

  @override
  Widget build(BuildContext context) => Column(
        children: [
          const TabHeader(
              title: 'Horario de atención',
              subtitle: 'Configura tu disponibilidad'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (final d in _h)
                  RLCard(
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(d.dia,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: RL.text)),
                              const SizedBox(height: 4),
                              if (d.activo)
                                Row(children: [
                                  ActionChip(
                                      label: Text(d.inicio),
                                      onPressed: () => _pick(d, true)),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 6),
                                    child: Text('–'),
                                  ),
                                  ActionChip(
                                      label: Text(d.fin),
                                      onPressed: () => _pick(d, false)),
                                ])
                              else
                                const Text('No disponible',
                                    style: TextStyle(color: RL.muted)),
                            ],
                          ),
                        ),
                        Column(children: [
                          Pill(d.activo ? 'Activo' : 'Inactivo',
                              color: d.activo ? RL.green : RL.muted,
                              bg: d.activo ? RL.greenSoft : RL.bg),
                          Switch(
                              value: d.activo,
                              onChanged: (v) => setState(() => d.activo = v)),
                        ]),
                      ],
                    ),
                  ),
                const SizedBox(height: 6),
                FilledButton(
                    onPressed: _guardar, child: const Text('GUARDAR CAMBIOS')),
              ],
            ),
          ),
        ],
      );
}
