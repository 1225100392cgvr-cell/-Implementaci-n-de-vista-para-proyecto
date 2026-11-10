import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets.dart';
import 'auth_screens.dart';
import 'perfil_screen.dart';

// ====================================================================== SHELL
class AdminShell extends StatefulWidget {
  const AdminShell({super.key});
  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _i = 0;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: IndexedStack(index: _i, children: [
          AdminHome(onGo: (n) => setState(() => _i = n)),
          const UsuariosScreen(),
          const AsignacionesScreen(),
          const PerfilScreen(),
        ]),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _i,
          onDestinationSelected: (n) => setState(() => _i = n),
          destinations: const [
            NavigationDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: 'Inicio'),
            NavigationDestination(
                icon: Icon(Icons.people_outline),
                selectedIcon: Icon(Icons.people),
                label: 'Usuarios'),
            NavigationDestination(
                icon: Icon(Icons.swap_horiz),
                selectedIcon: Icon(Icons.swap_horiz),
                label: 'Gestión'),
            NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: 'Perfil'),
          ],
        ),
      );
}

// ================================================================= DASHBOARD
class AdminHome extends StatelessWidget {
  final ValueChanged<int> onGo;
  const AdminHome({super.key, required this.onGo});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return Column(
      children: [
        TabHeader(
          title: 'Administrador',
          subtitle: 'Panel de control',
          trailing: const Pill('Rol: Administrador'),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const SectionLabel('Resumen'),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.9,
                children: [
                  StatCard(
                      valor: '${s.usuarios.length}',
                      label: 'Usuarios',
                      icon: Icons.people),
                  StatCard(
                      valor: '${s.contar(Rol.docente)}',
                      label: 'Docentes',
                      icon: Icons.badge,
                      color: RL.violet,
                      bg: RL.violetSoft),
                  StatCard(
                      valor: '${s.contar(Rol.alumno)}',
                      label: 'Alumnos',
                      icon: Icons.school,
                      color: RL.green,
                      bg: RL.greenSoft),
                  StatCard(
                      valor: '${s.grupos.length}',
                      label: 'Grupos',
                      icon: Icons.groups,
                      color: RL.amber,
                      bg: RL.amberSoft),
                ],
              ),
              const SizedBox(height: 8),
              const SectionLabel('Gestión'),
              ActionTile(
                  icon: Icons.people,
                  title: 'Usuarios y roles',
                  subtitle: 'Altas, roles y estado de cuentas',
                  onTap: () => onGo(1)),
              ActionTile(
                  icon: Icons.grid_view_rounded,
                  title: 'Materias y grupos',
                  subtitle: '${s.materias.length} materias · ${s.grupos.length} grupos',
                  onTap: () => onGo(2)),
              ActionTile(
                  icon: Icons.swap_horiz,
                  title: 'Asignaciones',
                  subtitle: '${s.asignaciones.length} activas',
                  onTap: () => onGo(2)),
              ActionTile(
                  icon: Icons.settings_outlined,
                  title: 'Sistema',
                  subtitle: 'RappoLink v1.0.0',
                  onTap: () => showAboutDialog(
                        context: context,
                        applicationName: 'RappoLink',
                        applicationVersion: '1.0.0',
                        children: const [
                          Text('Conecta. Comunica. Respeta.'),
                        ],
                      )),
            ],
          ),
        ),
      ],
    );
  }
}

// ================================================================== USUARIOS
class UsuariosScreen extends StatefulWidget {
  const UsuariosScreen({super.key});
  @override
  State<UsuariosScreen> createState() => _UsuariosScreenState();
}

class _UsuariosScreenState extends State<UsuariosScreen> {
  String _q = '';

  void _cambiarRol(BuildContext context, Usuario u) {
    final s = context.read<AppState>();
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text('Rol de ${u.nombre}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 16)),
            ),
            for (final r in Rol.values)
              ListTile(
                leading: Icon(
                    u.rol == r
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: RL.primary),
                title: Text(r.nombre),
                onTap: () {
                  s.cambiarRol(u, r);
                  Navigator.pop(context);
                  snack(context, '${u.nombre} ahora es ${r.nombre}');
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final lista = s.usuarios
        .where((u) =>
            '${u.nombre} ${u.correo}'.toLowerCase().contains(_q.toLowerCase()))
        .toList();
    return Scaffold(
      backgroundColor: RL.bg,
      floatingActionButton: FloatingActionButton(
        backgroundColor: RL.primary,
        foregroundColor: Colors.white,
        onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const NuevoUsuarioScreen())),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          const TabHeader(title: 'Usuarios', subtitle: 'Administrar cuentas'),
          SearchField(
              hint: 'Buscar usuario...',
              onChanged: (v) => setState(() => _q = v)),
          Expanded(
            child: lista.isEmpty
                ? const EmptyState(
                    icon: Icons.person_search,
                    title: 'No hay usuarios',
                    subtitle: 'Ningún usuario coincide con tu búsqueda.')
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                    itemCount: lista.length,
                    itemBuilder: (_, i) {
                      final u = lista[i];
                      final esYo = u.id == s.actual!.id;
                      return RLCard(
                        child: Row(
                          children: [
                            Avatar(u.inicial),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(u.nombre,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          color: RL.text)),
                                  Text(u.correo,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          color: RL.muted, fontSize: 12)),
                                  const SizedBox(height: 6),
                                  Wrap(spacing: 6, children: [
                                    GestureDetector(
                                      onTap: () => _cambiarRol(context, u),
                                      child: Pill('${u.rol.nombre} ▾',
                                          color: RL.violet,
                                          bg: RL.violetSoft),
                                    ),
                                    Pill(u.activo ? 'Activo' : 'Inactivo',
                                        color: u.activo ? RL.green : RL.red,
                                        bg: u.activo
                                            ? RL.greenSoft
                                            : RL.redSoft),
                                  ]),
                                ],
                              ),
                            ),
                            Switch(
                              value: u.activo,
                              onChanged:
                                  esYo ? null : (_) => s.toggleActivo(u),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ============================================== FORMULARIO: NUEVO USUARIO
class NuevoUsuarioScreen extends StatefulWidget {
  const NuevoUsuarioScreen({super.key});
  @override
  State<NuevoUsuarioScreen> createState() => _NuevoUsuarioScreenState();
}

class _NuevoUsuarioScreenState extends State<NuevoUsuarioScreen> {
  final _form = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _correo = TextEditingController();
  final _pass = TextEditingController(text: 'rappo123');
  Rol _rol = Rol.alumno;
  String? _grupo;
  String? _error;

  @override
  void dispose() {
    _nombre.dispose();
    _correo.dispose();
    _pass.dispose();
    super.dispose();
  }

  void _guardar() {
    if (!_form.currentState!.validate()) return;
    final s = context.read<AppState>();
    final err = s.crearUsuario(
      nombre: _nombre.text,
      correo: _correo.text,
      password: _pass.text,
      rol: _rol,
      grupo: _grupo ?? s.grupos.first,
    );
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    snack(context, 'Usuario creado correctamente');
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final grupos = context.watch<AppState>().grupos;
    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo usuario')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nombre,
                textCapitalization: TextCapitalization.words,
                validator: (v) => (v == null || v.trim().length < 3)
                    ? 'Ingresa el nombre completo'
                    : null,
                decoration: const InputDecoration(labelText: 'Nombre completo'),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _correo,
                keyboardType: TextInputType.emailAddress,
                validator: validarCorreo,
                decoration:
                    const InputDecoration(labelText: 'Correo institucional'),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _pass,
                validator: validarPassword,
                decoration:
                    const InputDecoration(labelText: 'Contraseña inicial'),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<Rol>(
                value: _rol,
                items: Rol.values
                    .map((r) =>
                        DropdownMenuItem(value: r, child: Text(r.nombre)))
                    .toList(),
                onChanged: (v) => setState(() => _rol = v ?? Rol.alumno),
                decoration: const InputDecoration(labelText: 'Rol'),
              ),
              if (_rol == Rol.alumno) ...[
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: _grupo ?? grupos.first,
                  items: grupos
                      .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                      .toList(),
                  onChanged: (v) => setState(() => _grupo = v),
                  decoration: const InputDecoration(labelText: 'Grupo'),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: RL.red)),
              ],
              const SizedBox(height: 24),
              FilledButton(
                  onPressed: _guardar, child: const Text('GUARDAR USUARIO')),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================= GESTIÓN ACADÉMICA (3 tabs)
class AsignacionesScreen extends StatelessWidget {
  const AsignacionesScreen({super.key});

  Future<void> _dialogoAgregar(
      BuildContext context, String titulo, void Function(String) onOk) async {
    final c = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(titulo),
        content: TextField(
            controller: c,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Nombre')),
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
    if (ok == true) onOk(c.text);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          const TabHeader(
              title: 'Asignaciones', subtitle: 'Docentes · materias · grupos'),
          Container(
            color: Colors.white,
            child: const TabBar(
              tabs: [
                Tab(text: 'Materias'),
                Tab(text: 'Grupos'),
                Tab(text: 'Asignaciones'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                // ---- Materias
                Column(children: [
                  Expanded(
                    child: s.materias.isEmpty
                        ? const EmptyState(
                            icon: Icons.menu_book_outlined,
                            title: 'No hay materias')
                        : ListView(
                            padding: const EdgeInsets.all(16),
                            children: [
                              for (final m in s.materias)
                                RLCard(
                                  child: Row(children: [
                                    const Avatar('M'),
                                    const SizedBox(width: 12),
                                    Text(m,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w700)),
                                  ]),
                                ),
                            ],
                          ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: FilledButton(
                      onPressed: () => _dialogoAgregar(
                          context, 'Nueva materia', s.agregarMateria),
                      child: const Text('+ NUEVA MATERIA'),
                    ),
                  ),
                ]),
                // ---- Grupos
                Column(children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        for (final g in s.grupos)
                          RLCard(
                            child: Row(children: [
                              const Avatar('G',
                                  bg: RL.violetSoft, fg: RL.violet),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(g,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700)),
                              ),
                              Text(
                                  '${s.usuarios.where((u) => u.grupo == g).length} alumnos',
                                  style: const TextStyle(
                                      color: RL.muted, fontSize: 12)),
                            ]),
                          ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: FilledButton(
                      onPressed: () => _dialogoAgregar(
                          context, 'Nuevo grupo', s.agregarGrupo),
                      child: const Text('+ NUEVO GRUPO'),
                    ),
                  ),
                ]),
                // ---- Asignaciones
                Column(children: [
                  Expanded(
                    child: s.asignaciones.isEmpty
                        ? const EmptyState(
                            icon: Icons.swap_horiz,
                            title: 'No hay asignaciones',
                            subtitle:
                                'Crea una para que los alumnos vean a sus docentes.')
                        : ListView(
                            padding: const EdgeInsets.all(16),
                            children: [
                              const SectionLabel('Asignaciones activas'),
                              for (final a in s.asignaciones)
                                RLCard(
                                  child: Row(children: [
                                    Avatar(s.usuario(a.docenteId).inicial),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(s.usuario(a.docenteId).nombre,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w800)),
                                          Text(a.materia,
                                              style: const TextStyle(
                                                  color: RL.muted,
                                                  fontSize: 13)),
                                        ],
                                      ),
                                    ),
                                    Pill(a.grupo),
                                  ]),
                                ),
                            ],
                          ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const NuevaAsignacionScreen())),
                      child: const Text('+ NUEVA ASIGNACIÓN'),
                    ),
                  ),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ========================================= FORMULARIO: NUEVA ASIGNACIÓN
class NuevaAsignacionScreen extends StatefulWidget {
  const NuevaAsignacionScreen({super.key});
  @override
  State<NuevaAsignacionScreen> createState() => _NuevaAsignacionScreenState();
}

class _NuevaAsignacionScreenState extends State<NuevaAsignacionScreen> {
  String? _docente;
  String? _materia;
  String? _grupo;
  String? _error;

  void _guardar() {
    if (_docente == null || _materia == null || _grupo == null) {
      setState(() => _error = 'Selecciona docente, materia y grupo.');
      return;
    }
    final err =
        context.read<AppState>().crearAsignacion(_docente!, _materia!, _grupo!);
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    snack(context, 'Asignación creada');
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(title: const Text('Nueva asignación')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          DropdownButtonFormField<String>(
            value: _docente,
            hint: const Text('Selecciona un docente'),
            items: s.docentes
                .where((d) => d.activo)
                .map((d) => DropdownMenuItem(value: d.id, child: Text(d.nombre)))
                .toList(),
            onChanged: (v) => setState(() => _docente = v),
            decoration: const InputDecoration(labelText: 'Docente'),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            value: _materia,
            hint: const Text('Selecciona una materia'),
            items: s.materias
                .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                .toList(),
            onChanged: (v) => setState(() => _materia = v),
            decoration: const InputDecoration(labelText: 'Materia'),
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
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: RL.red)),
          ],
          const SizedBox(height: 24),
          FilledButton(
              onPressed: _guardar, child: const Text('GUARDAR ASIGNACIÓN')),
        ],
      ),
    );
  }
}
