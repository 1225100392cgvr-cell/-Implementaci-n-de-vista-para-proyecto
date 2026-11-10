import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets.dart';

// ============================================================ LISTA DE CHATS
/// Bandeja compartida: la misma lista cambia de perspectiva según el rol.
class ChatsScreen extends StatefulWidget {
  const ChatsScreen({super.key});
  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final me = s.actual!;
    final esDocente = me.rol == Rol.docente;
    final todas = s.conversacionesDe(me);
    final lista = todas.where((c) {
      final otro = s.usuario(esDocente ? c.alumnoId : c.docenteId);
      final t = '${otro.nombre} ${c.materia}'.toLowerCase();
      return t.contains(_q.toLowerCase());
    }).toList();

    return Column(
      children: [
        TabHeader(
          title: 'Chats',
          subtitle: esDocente
              ? 'Conversaciones con alumnos'
              : 'Conversaciones con docentes',
        ),
        SearchField(
            hint: 'Buscar conversación...',
            onChanged: (v) => setState(() => _q = v)),
        Expanded(
          child: lista.isEmpty
              ? EmptyState(
                  icon: Icons.chat_bubble_outline,
                  title: todas.isEmpty
                      ? 'No hay conversaciones'
                      : 'Sin resultados',
                  subtitle: todas.isEmpty
                      ? (esDocente
                          ? 'Cuando un alumno te escriba, aparecerá aquí.'
                          : 'Entra a "Docentes" y abre un chat para comenzar.')
                      : 'Prueba con otro nombre o materia.',
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: lista.length,
                  itemBuilder: (_, i) {
                    final c = lista[i];
                    final otro =
                        s.usuario(esDocente ? c.alumnoId : c.docenteId);
                    final noLeidos =
                        esDocente ? c.noLeidosDocente : c.noLeidosAlumno;
                    final u = c.ultimo;
                    return RLCard(
                      onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => ChatScreen(convId: c.id))),
                      child: Row(
                        children: [
                          Avatar(otro.inicial),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(otro.nombre,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        color: RL.text)),
                                Text(c.materia,
                                    style: const TextStyle(
                                        color: RL.primary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600)),
                                const SizedBox(height: 2),
                                Text(u?.texto ?? 'Sin mensajes',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        color: RL.muted, fontSize: 13)),
                              ],
                            ),
                          ),
                          if (noLeidos > 0)
                            Container(
                              width: 24,
                              height: 24,
                              alignment: Alignment.center,
                              decoration: const BoxDecoration(
                                  color: RL.primary, shape: BoxShape.circle),
                              child: Text('$noLeidos',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800)),
                            ),
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

// ==================================================================== CHAT
class ChatScreen extends StatefulWidget {
  final String convId;
  const ChatScreen({super.key, required this.convId});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _txt = TextEditingController();
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AppState>().marcarLeida(widget.convId);
    });
  }

  @override
  void dispose() {
    _txt.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _bajar() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent + 80,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut);
      }
    });
  }

  Future<void> _enviar() async {
    final texto = _txt.text.trim();
    if (texto.isEmpty) return;
    final s = context.read<AppState>();
    final c = s.conversacion(widget.convId);
    final me = s.actual!;

    // Un alumno fuera del horario del docente → mensaje programado.
    if (me.rol == Rol.alumno && !s.dentroDeHorario(c.docenteId)) {
      final ok = await Navigator.of(context).push<bool>(MaterialPageRoute(
          builder: (_) =>
              ProgramarMensajeScreen(convId: c.id, texto: texto)));
      if (ok == true) {
        _txt.clear();
        _bajar();
      }
      return;
    }
    s.enviarMensaje(c.id, texto);
    _txt.clear();
    _bajar();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final me = s.actual!;
    final c = s.conversacion(widget.convId);
    final esDocente = me.rol == Rol.docente;
    final otro = s.usuario(esDocente ? c.alumnoId : c.docenteId);
    final sub = esDocente
        ? c.materia
        : '${c.materia} · ${s.textoDisponibilidad(c.docenteId)}';

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(children: [
          Avatar(otro.inicial, size: 36),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(esDocente ? otro.nombre : 'Prof. ${otro.nombre}',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w800)),
                Text(sub,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 11,
                        color: RL.muted,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ]),
      ),
      body: Column(
        children: [
          Expanded(
            child: c.mensajes.isEmpty
                ? const EmptyState(
                    icon: Icons.waving_hand_outlined,
                    title: 'Inicia la conversación',
                    subtitle: 'Escribe tu primer mensaje abajo.')
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.all(16),
                    itemCount: c.mensajes.length,
                    itemBuilder: (_, i) =>
                        _Burbuja(m: c.mensajes[i], mio: c.mensajes[i].deId == me.id),
                  ),
          ),
          SafeArea(
            top: false,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _txt,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _enviar(),
                      decoration: const InputDecoration(
                          hintText: 'Escribe un mensaje...', isDense: true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Material(
                    color: RL.primary,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _enviar,
                      child: const Padding(
                        padding: EdgeInsets.all(12),
                        child: Icon(Icons.send_rounded,
                            color: Colors.white, size: 22),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Burbuja extends StatelessWidget {
  final Mensaje m;
  final bool mio;
  const _Burbuja({required this.m, required this.mio});

  @override
  Widget build(BuildContext context) {
    final prog = m.estado == EstadoMensaje.programado;
    return Align(
      alignment: mio ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * .75),
        decoration: BoxDecoration(
          color: mio ? (prog ? RL.amber : RL.primary) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(mio ? 16 : 4),
            bottomRight: Radius.circular(mio ? 4 : 16),
          ),
          border: mio ? null : Border.all(color: RL.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(m.texto,
                style: TextStyle(
                    color: mio ? Colors.white : RL.text, height: 1.3)),
            const SizedBox(height: 4),
            Row(mainAxisSize: MainAxisSize.min, children: [
              if (prog) ...[
                const Icon(Icons.schedule, size: 12, color: Colors.white),
                const SizedBox(width: 3),
                Text('Programado · ${m.etiquetaEntrega ?? ''}',
                    style: const TextStyle(color: Colors.white, fontSize: 10)),
              ] else
                Text(fmtHora(m.hora) + (mio ? ' ✓' : ''),
                    style: TextStyle(
                        color: mio ? Colors.white70 : RL.muted, fontSize: 10)),
            ]),
          ],
        ),
      ),
    );
  }
}

// ======================================================= MENSAJE PROGRAMADO
class ProgramarMensajeScreen extends StatelessWidget {
  final String convId;
  final String texto;
  const ProgramarMensajeScreen(
      {super.key, required this.convId, required this.texto});

  @override
  Widget build(BuildContext context) {
    final s = context.read<AppState>();
    final c = s.conversacion(convId);
    final docente = s.usuario(c.docenteId);
    final disp = s.proximaDisponibilidad(c.docenteId);

    return Scaffold(
      appBar: AppBar(title: const Text('Mensaje programado')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Center(
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: const BoxDecoration(
                      color: RL.amberSoft, shape: BoxShape.circle),
                  child: const Icon(Icons.schedule,
                      size: 48, color: RL.amber),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Fuera del horario\nde atención',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: RL.text)),
              const SizedBox(height: 8),
              Text('El profesor ${docente.nombre} no recibirá el mensaje en este momento.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: RL.muted, height: 1.4)),
              const SizedBox(height: 20),
              RLCard(
                color: RL.soft,
                child: Text('“$texto”',
                    style: const TextStyle(
                        fontStyle: FontStyle.italic, color: RL.text2)),
              ),
              const SizedBox(height: 6),
              RLCard(
                color: RL.amberSoft,
                child: Row(
                  children: [
                    const Icon(Icons.event_available, color: RL.amber),
                    const SizedBox(width: 10),
                    const Expanded(
                        child: Text('Tu mensaje se entregará:',
                            style: TextStyle(color: RL.text2))),
                    Text(disp.etiqueta,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, color: RL.text)),
                  ],
                ),
              ),
              const Spacer(),
              FilledButton(
                onPressed: () {
                  s.programarMensaje(convId, texto, disp);
                  snack(context, 'Mensaje programado para ${disp.etiqueta}');
                  Navigator.of(context).pop(true);
                },
                child: const Text('PROGRAMAR MENSAJE'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
