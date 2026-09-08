import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roommatematch/features/auth/welcome_screen.dart';

void main() {
  testWidgets('WelcomeScreen muestra botones de acción', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: WelcomeScreen()));

    expect(find.text('Crear cuenta'), findsOneWidget);
    expect(find.text('Iniciar sesión'), findsOneWidget);
    expect(find.text('Regístrate'), findsOneWidget);
  });
}
