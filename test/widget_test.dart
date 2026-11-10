import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:rappolinkaplicacion/app_state.dart';
import 'package:rappolinkaplicacion/main.dart';

void main() {
  testWidgets('Splash muestra RappoLink y luego el login', (tester) async {
    await tester.pumpWidget(ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const RappoLinkApp(),
    ));
    expect(find.text('RappoLink'), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    expect(find.text('INICIAR SESIÓN'), findsOneWidget);
  });
}
