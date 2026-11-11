import 'package:flutter_test/flutter_test.dart';
import 'package:rappolinkaplicacion/app_state.dart';
import 'package:rappolinkaplicacion/models.dart';

void main() {
  test('Inscribir a un alumno lo cambia de grupo y da de baja la anterior', () {
    final s = AppState();
    final antes = s.inscritosEn('GSI-52');
    expect(s.inscribir('u7', 'GSI-52', DateTime(2026, 11, 10),
        EstadoInscripcion.activa), isNull);
    expect(s.usuario('u7').grupo, 'GSI-52');
    expect(s.inscritosEn('GSI-52'), antes + 1);
  });

  test('No se puede inscribir dos veces al mismo grupo', () {
    final s = AppState();
    expect(s.inscribir('u6', 'GSI-51', DateTime(2026, 11, 10),
        EstadoInscripcion.activa), isNotNull);
  });

  test('Cancelar un mensaje programado cambia su estado', () {
    final s = AppState();
    s.login('angel@institucion.edu.mx', 'alumno123');
    final p = s
        .programadosDe(s.actual!)
        .firstWhere((p) => p.estado == EstadoProgramado.pendiente);
    s.cancelarProgramado(p);
    expect(p.estado, EstadoProgramado.cancelado);
  });

  test('Los avisos se marcan como leídos', () {
    final s = AppState();
    s.login('carlos@institucion.edu.mx', 'docente123');
    final total = s.avisosSinLeer(s.actual!);
    expect(total, greaterThan(0));
    s.marcarAviso(s.avisosDe(s.actual!).first.id);
    expect(s.avisosSinLeer(s.actual!), total - 1);
  });
}
