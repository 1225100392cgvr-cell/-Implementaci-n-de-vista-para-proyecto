import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../theme.dart';
import '../widgets.dart';
import 'chat_screens.dart';
import 'perfil_screen.dart';

// ====================================================================== SHELL
class AlumnoShell extends StatefulWidget {
  const AlumnoShell({super.key});
  @override
  State<AlumnoShell> createState() => _AlumnoShellState();
}

class _AlumnoShellState extends State<AlumnoShell> {
  int _i = 0;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final nuevos = s.pendientesAlumno(s.actual!.id);
    return Scaffold(
      body: IndexedStack(index: _i, children: [
        AlumnoHome(onGo: (n) => setState(() => _i = n)),
        const MisDocentesScreen(),
        const ChatsScreen(),
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
          const NavigationDestination(
              icon: Icon(Icons.groups_outlined),
              selectedIcon: Icon(Icons.groups),
              label: 'Docentes'),
          NavigationDestination(
              icon: Badge(
                  isLabelVisible: nuevos > 0,
                  label: Text('$nuevos'),
                  child: const Icon(Icons.chat_bubble_outline)),
              selectedIcon: const Icon(Icons.chat_bubble),
              label: 'Chats'),
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
class AlumnoHome extends StatelessWidget {
  final ValueChanged<int> onGo;
  const AlumnoHome({super.key, required this.onGo});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final me = s.actual!;
    final asigs = s.docentesDeAlumno(me);
    final disponibles =
        asigs.where((a) => s.dentroDeHorario(a.docenteId)).length;
    final nuevos = s.pendientesAlumno(me.id);
    final materias = asigs.map((a) => a.materia).toSet().length;

    return Column(
      children: [
        TabHeader(
          title: 'Hola, ${me.primerNombre} 👋',
          subtitle: 'Alumno · ${me.grupo ?? 'Sin grupo'}',
          trailing: const Pill('Rol: Alumno'),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const HorarioBanner(
                dentro: true,
                titulo: 'Horario institucional activo',
                detalle: '07:00 – 18:00',
              ),
              const SizedBox(height: 8),
              const SectionLabel('Accesos rápidos'),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 10,
                mainAxisSpacing: 0,
                childAspectRatio: 1.35,
                children: [
                  _Acceso(
                    icon: Icons.groups,
                    titulo: 'Docentes',
                    detalle: '$disponibles disponibles',
                    onTap: () => onGo(1),
                  ),
                  _Acceso(
                    icon: Icons.chat_bubble,
                    titulo: 'Chats',
                    detalle: '$nuevos nuevos',
                    color: RL.violet,
                    bg: RL.violetSoft,
                    onTap: () => onGo(2),
                  ),
                  _Acceso(
                    icon: Icons.menu_book,
                    titulo: 'Materias',
                    detalle: '$materias activas',
                    color: RL.green,
                    bg: RL.greenSoft,
                    onTap: () => onGo(1),
                  ),
                  _Acceso(
                    icon: Icons.person,
                    titulo: 'Perfil',
                    detalle: 'Cuenta institucional',
                    color: RL.amber,
                    bg: RL.amberSoft,
                    onTap: () => onGo(3),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Acceso extends StatelessWidget {
  final IconData icon;
  final String titulo;
  final String detalle;
  final VoidCallback onTap;
  final Color color;
  final Color bg;
  const _Acceso(
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
          mainAxisAlignment: MainAxisAlignment.center,
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

// ================================================================ MIS DOCENTES
class MisDocentesScreen extends StatefulWidget {
  const MisDocentesScreen({super.key});
  @override
  State<MisDocentesScreen> createState() => _MisDocentesScreenState();
}

class _MisDocentesScreenState extends State<MisDocentesScreen> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final me = s.actual!;
    final todas = s.docentesDeAlumno(me);
    final lista = todas.where((a) {
      final d = s.usuario(a.docenteId);
      return '${d.nombre} ${a.materia}'.toLowerCase().contains(_q.toLowerCase());
    }).toList();

    return Column(
      children: [
        TabHeader(
            title: 'Mis docentes',
            subtitle: me.grupo ?? '',
            trailing: Pill('${todas.length} docentes')),
        SearchField(
            hint: 'Buscar docente o materia...',
            onChanged: (v) => setState(() => _q = v)),
        Expanded(
          child: lista.isEmpty
              ? EmptyState(
                  icon: Icons.person_search,
                  title: todas.isEmpty
                      ? 'No hay docentes asignados'
                      : 'Sin resultados',
                  subtitle: todas.isEmpty
                      ? 'El administrador aún no asigna docentes a tu grupo.'
                      : 'Prueba con otro nombre o materia.',
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: lista.length,
                  itemBuilder: (_, i) {
                    final a = lista[i];
                    final d = s.usuario(a.docenteId);
                    final dentro = s.dentroDeHorario(d.id);
                    return RLCard(
                      onTap: () {
                        final c = s.conversacionPara(me, a);
                        Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => ChatScreen(convId: c.id)));
                      },
                      child: Row(
                        children: [
                          Avatar(d.inicial),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(d.nombre,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        color: RL.text)),
                                Text(a.materia,
                                    style: const TextStyle(
                                        color: RL.muted, fontSize: 13)),
                              ],
                            ),
                          ),
                          Pill(dentro ? 'Dentro de horario' : 'Fuera de horario',
                              color: dentro ? RL.green : RL.amber,
                              bg: dentro ? RL.greenSoft : RL.amberSoft),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
