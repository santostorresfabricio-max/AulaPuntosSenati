import 'package:flutter/material.dart';
import 'core/theme/senati_theme.dart';
import 'presentation/controllers/app_controller.dart';
import 'presentation/screens/login_screen.dart';
import 'presentation/screens/main_shell_screen.dart';

void main() {
  runApp(const AulaPuntosSenatiApp());
}

class AulaPuntosSenatiApp extends StatefulWidget {
  const AulaPuntosSenatiApp({super.key});

  @override
  State<AulaPuntosSenatiApp> createState() => _AulaPuntosSenatiAppState();
}

class _AulaPuntosSenatiAppState extends State<AulaPuntosSenatiApp> {
  final AppController _appController = AppController();

  @override
  void dispose() {
    _appController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _appController,
      builder: (context, _) {
        return MaterialApp(
          title: 'Aula Puntos - SENATI',
          debugShowCheckedModeBanner: false,
          theme: SenatiTheme.lightTheme,
          home: _appController.isAuthenticated
              ? MainShellScreen(controller: _appController)
              : LoginScreen(controller: _appController),
        );
      },
    );
  }
}
