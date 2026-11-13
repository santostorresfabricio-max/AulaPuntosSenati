import 'package:flutter/material.dart';
import '../../core/theme/senati_theme.dart';
import '../controllers/app_controller.dart';

class LoginScreen extends StatefulWidget {
  final AppController controller;

  const LoginScreen({super.key, required this.controller});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userController = TextEditingController(text: 'cmendoza@senati.pe');
  final _passwordController = TextEditingController(text: '••••••••••••');
  bool _obscurePassword = true;
  bool _rememberSession = true;

  @override
  void dispose() {
    _userController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submitLogin() {
    if (_formKey.currentState?.validate() ?? false) {
      widget.controller.login(_userController.text, _passwordController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 900;

    return Scaffold(
      backgroundColor: SenatiTheme.backgroundGrey,
      body: Row(
        children: [
          if (isDesktop)
            Expanded(
              flex: 5,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF002855),
                      SenatiTheme.primaryBlue,
                      SenatiTheme.secondaryBlue,
                    ],
                  ),
                ),
                padding: const EdgeInsets.all(48),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.school_rounded,
                            color: SenatiTheme.primaryBlue,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'SENATI',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5,
                              ),
                            ),
                            Text(
                              'Escuela de Tecnologías de la Información',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'PLATAFORMA DOCENTE OFFLINE-FIRST',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Aula Puntos\nSENATI',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 44,
                            height: 1.1,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'Centraliza la gestión de grupos, sesiones académicas, control ágil de asistencia y puntuación por participación en tiempo real.',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 32),
                        _buildFeatureRow(
                          Icons.bolt_rounded,
                          'Asistencia y puntos en 1 solo clic durante la sesión.',
                        ),
                        const SizedBox(height: 12),
                        _buildFeatureRow(
                          Icons.cloud_sync_rounded,
                          'Soporte Online/Offline con almacenamiento local automático.',
                        ),
                        const SizedBox(height: 12),
                        _buildFeatureRow(
                          Icons.picture_as_pdf_rounded,
                          'Reportes consolidados listos para exportar a PDF y Excel.',
                        ),
                      ],
                    ),
                    const Text(
                      '© 2026 SENATI • Sistema de Apoyo al Instructor v1.0',
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          Expanded(
            flex: 6,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 430),
                  child: Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: SenatiTheme.borderGrey),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: SenatiTheme.lightBlue,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.verified_user_rounded,
                                    color: SenatiTheme.primaryBlue,
                                    size: 26,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Portal del Instructor',
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w800,
                                          color: SenatiTheme.textPrimary,
                                        ),
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        'Aula Puntos - SENATI',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: SenatiTheme.textSecondary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 28),
                            const Text(
                              'Usuario o Correo Institucional',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: SenatiTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _userController,
                              decoration: const InputDecoration(
                                hintText: 'ejemplo@senati.pe o ID Instructor',
                                prefixIcon: Icon(Icons.badge_outlined),
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Ingrese su usuario institucional';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'Contraseña',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: SenatiTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                hintText: 'Ingrese su contraseña',
                                prefixIcon: const Icon(Icons.lock_outline_rounded),
                                suffixIcon: IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                  ),
                                ),
                              ),
                              validator: (val) {
                                if (val == null || val.isEmpty) {
                                  return 'Ingrese su contraseña';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Checkbox(
                                  value: _rememberSession,
                                  activeColor: SenatiTheme.primaryBlue,
                                  onChanged: (v) {
                                    setState(() {
                                      _rememberSession = v ?? true;
                                    });
                                  },
                                ),
                                const Expanded(
                                  child: Text(
                                    'Mantener sesión activa para trabajo Offline',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: SenatiTheme.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              height: 48,
                              child: ElevatedButton.icon(
                                onPressed: _submitLogin,
                                icon: const Icon(Icons.login_rounded, size: 20),
                                label: const Text('INGRESAR AL PANEL'),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: SenatiTheme.lightBlue,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Row(
                                children: [
                                  Icon(
                                    Icons.info_outline_rounded,
                                    size: 18,
                                    color: SenatiTheme.primaryBlue,
                                  ),
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Credenciales de prueba pre-cargadas. Presione "INGRESAR AL PANEL" para validar la experiencia.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: SenatiTheme.primaryBlue,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String text) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ),
      ],
    );
  }
}
