import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets.dart';

final _emailRe = RegExp(r'^[\w.\-+]+@[\w\-]+(\.[\w\-]+)+$');

String? validarCorreo(String? v) {
  final t = (v ?? '').trim();
  if (t.isEmpty) return 'Ingresa tu correo institucional';
  if (!_emailRe.hasMatch(t)) return 'Correo no válido (usuario@institucion.edu.mx)';
  return null;
}

String? validarPassword(String? v) {
  if (v == null || v.isEmpty) return 'Ingresa tu contraseña';
  if (v.length < 6) return 'Mínimo 6 caracteres';
  return null;
}

// ===================================================================== LOGIN
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _correo = TextEditingController();
  final _pass = TextEditingController();
  bool _ver = false;
  String? _error;

  @override
  void dispose() {
    _correo.dispose();
    _pass.dispose();
    super.dispose();
  }

  void _entrar() {
    setState(() => _error = null);
    if (!_form.currentState!.validate()) return;
    final err = context.read<AppState>().login(_correo.text, _pass.text);
    if (err != null) setState(() => _error = err);
    // Si es null, Root detecta la sesión y muestra la interfaz del rol.
  }

  void _demo(String correo, String pass) {
    _correo.text = correo;
    _pass.text = pass;
    setState(() => _error = null);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),
                  const Center(child: RLLogo(size: 78)),
                  const SizedBox(height: 18),
                  const Text('RappoLink',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: RL.text)),
                  const SizedBox(height: 4),
                  const Text('Bienvenido',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: RL.primary)),
                  const SizedBox(height: 4),
                  const Text('Inicia sesión con tu cuenta institucional',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: RL.muted)),
                  const SizedBox(height: 28),
                  TextFormField(
                    controller: _correo,
                    keyboardType: TextInputType.emailAddress,
                    validator: validarCorreo,
                    decoration: const InputDecoration(
                      labelText: 'Correo institucional',
                      hintText: 'usuario@institucion.edu.mx',
                      prefixIcon: Icon(Icons.mail_outline),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _pass,
                    obscureText: !_ver,
                    validator: validarPassword,
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                            _ver ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _ver = !_ver),
                      ),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          color: RL.redSoft,
                          borderRadius: BorderRadius.circular(12)),
                      child: Row(children: [
                        const Icon(Icons.error_outline,
                            color: RL.red, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                            child: Text(_error!,
                                style: const TextStyle(color: RL.red))),
                      ]),
                    ),
                  ],
                  const SizedBox(height: 22),
                  FilledButton(
                      onPressed: _entrar, child: const Text('INICIAR SESIÓN')),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const RegisterScreen())),
                    child: const Text('¿No tienes cuenta? Regístrate'),
                  ),
                  const SizedBox(height: 14),
                  const Text('Cuentas de prueba (toca para rellenar)',
                      style: TextStyle(color: RL.muted, fontSize: 12)),
                  const SizedBox(height: 8),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    ActionChip(
                        label: const Text('Administrador'),
                        onPressed: () => _demo(
                            'admin@institucion.edu.mx', 'admin123')),
                    ActionChip(
                        label: const Text('Docente'),
                        onPressed: () => _demo(
                            'carlos@institucion.edu.mx', 'docente123')),
                    ActionChip(
                        label: const Text('Alumno'),
                        onPressed: () => _demo(
                            'angel@institucion.edu.mx', 'alumno123')),
                  ]),
                ],
              ),
            ),
          ),
        ),
      );
}

// ================================================================== REGISTRO
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _correo = TextEditingController();
  final _pass = TextEditingController();
  final _pass2 = TextEditingController();
  Rol _rol = Rol.alumno;
  String? _grupo;
  String? _error;

  @override
  void dispose() {
    _nombre.dispose();
    _correo.dispose();
    _pass.dispose();
    _pass2.dispose();
    super.dispose();
  }

  void _registrar() {
    setState(() => _error = null);
    if (!_form.currentState!.validate()) return;
    final s = context.read<AppState>();
    final err = s.registrar(
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
    // Cierra el registro; Root ya muestra la interfaz del rol.
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final grupos = context.watch<AppState>().grupos;
    return Scaffold(
      appBar: AppBar(title: const Text('Crear cuenta')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Selecciona tu rol',
                    style:
                        TextStyle(fontWeight: FontWeight.w800, color: RL.text)),
                const SizedBox(height: 10),
                SegmentedButton<Rol>(
                  segments: const [
                    ButtonSegment(
                        value: Rol.alumno,
                        label: Text('Alumno'),
                        icon: Icon(Icons.school_outlined)),
                    ButtonSegment(
                        value: Rol.docente,
                        label: Text('Docente'),
                        icon: Icon(Icons.badge_outlined)),
                    ButtonSegment(
                        value: Rol.admin,
                        label: Text('Admin'),
                        icon: Icon(Icons.admin_panel_settings_outlined)),
                  ],
                  selected: {_rol},
                  onSelectionChanged: (s) => setState(() => _rol = s.first),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _nombre,
                  textCapitalization: TextCapitalization.words,
                  validator: (v) => (v == null || v.trim().length < 3)
                      ? 'Ingresa tu nombre completo'
                      : null,
                  decoration: const InputDecoration(
                      labelText: 'Nombre completo',
                      prefixIcon: Icon(Icons.person_outline)),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _correo,
                  keyboardType: TextInputType.emailAddress,
                  validator: validarCorreo,
                  decoration: const InputDecoration(
                      labelText: 'Correo institucional',
                      hintText: 'usuario@institucion.edu.mx',
                      prefixIcon: Icon(Icons.mail_outline)),
                ),
                if (_rol == Rol.alumno) ...[
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    value: _grupo ?? grupos.first,
                    items: grupos
                        .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                        .toList(),
                    onChanged: (v) => setState(() => _grupo = v),
                    decoration: const InputDecoration(
                        labelText: 'Grupo',
                        prefixIcon: Icon(Icons.groups_outlined)),
                  ),
                ],
                const SizedBox(height: 14),
                TextFormField(
                  controller: _pass,
                  obscureText: true,
                  validator: validarPassword,
                  decoration: const InputDecoration(
                      labelText: 'Contraseña',
                      prefixIcon: Icon(Icons.lock_outline)),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _pass2,
                  obscureText: true,
                  validator: (v) =>
                      v != _pass.text ? 'Las contraseñas no coinciden' : null,
                  decoration: const InputDecoration(
                      labelText: 'Confirmar contraseña',
                      prefixIcon: Icon(Icons.lock_reset)),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: RL.red)),
                ],
                const SizedBox(height: 24),
                FilledButton(
                    onPressed: _registrar, child: const Text('CREAR CUENTA')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
