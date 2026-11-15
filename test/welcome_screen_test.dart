import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/screens/welcome_screen.dart';

void main() {
  testWidgets('welcome carousel advances automatically after five seconds', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: WelcomeScreen()));

    expect(find.text('Gestión Integral de Citas'), findsOneWidget);

    await tester.pump(const Duration(seconds: 4));
    expect(find.text('Gestión Integral de Citas'), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('Asistencia y Chat en Vivo'), findsOneWidget);
  });
}
