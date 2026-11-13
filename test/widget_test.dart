import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aula_puntos_senati/main.dart';

void main() {
  testWidgets('Valida responsividad en pantalla movil (360x800) en todas las vistas sin overflow', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const AulaPuntosSenatiApp());

    // 1. Login
    expect(find.text('Portal del Instructor'), findsOneWidget);
    await tester.tap(find.text('INGRESAR AL PANEL'));
    await tester.pumpAndSettle();

    // 2. Dashboard
    expect(find.text('AULA PUNTOS - SENATI'), findsOneWidget);
    expect(find.text('Gestionar Grupos'), findsOneWidget);

    // 3. Grupos y Sesiones
    await tester.tap(find.text('Grupos').last);
    await tester.pumpAndSettle();
    expect(find.text('Gestión de Grupos Asignados'), findsOneWidget);

    // Entrar a detalle de sesiones de un grupo
    await tester.tap(find.text('Sesiones').first);
    await tester.pumpAndSettle();
    expect(find.text('Crear Nueva Sesión Rápida'), findsOneWidget);

    // 4. Control de Asistencia
    await tester.tap(find.text('Asistencia').last);
    await tester.pumpAndSettle();
    expect(find.text('Control Ágil de Asistencia'), findsOneWidget);

    // 5. Puntuación Rápida
    await tester.tap(find.text('Puntos').last);
    await tester.pumpAndSettle();
    expect(find.text('Puntuación Rápida de Participación'), findsOneWidget);

    // 6. Reportes y Exportación
    await tester.tap(find.text('Reportes').last);
    await tester.pumpAndSettle();
    expect(find.text('Reportes Consolidados y Exportación'), findsOneWidget);
  });
}
