import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets.dart';

class PerfilScreen extends StatelessWidget {
  const PerfilScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final u = s.actual!;
    return Column(
      children: [
        const TabHeader(title: 'Perfil', subtitle: 'Cuenta institucional'),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              RLCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Avatar(u.inicial, size: 72),
                    const SizedBox(height: 12),
                    Text(u.nombre,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: RL.text)),
                    const SizedBox(height: 2),
                    Text(u.correo, style: const TextStyle(color: RL.muted)),
                    const SizedBox(height: 10),
                    Wrap(spacing: 8, children: [
                      Pill(u.rol.nombre),
                      if (u.grupo != null)
                        Pill(u.grupo!, color: RL.violet, bg: RL.violetSoft),
                    ]),
                  ],
                ),
              ),
              const SectionLabel('Demostración · horario de atención'),
              RLCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Fuerza si los docentes están dentro o fuera de horario para probar los mensajes programados.',
                      style: TextStyle(color: RL.muted, fontSize: 13),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<ModoHorario>(
                        segments: const [
                          ButtonSegment(
                              value: ModoHorario.auto, label: Text('Real')),
                          ButtonSegment(
                              value: ModoHorario.dentro, label: Text('Dentro')),
                          ButtonSegment(
                              value: ModoHorario.fuera, label: Text('Fuera')),
                        ],
                        selected: {s.modoHorario},
                        onSelectionChanged: (v) => s.setModoHorario(v.first),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  foregroundColor: RL.red,
                  side: const BorderSide(color: RL.red),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.logout),
                label: const Text('Cerrar sesión'),
                onPressed: () => s.logout(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
