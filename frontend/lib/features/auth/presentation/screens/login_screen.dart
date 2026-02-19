import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../services/presentation/screens/layout/client_main_layout.dart';
import '../../../services/presentation/screens/layout/worker_main_layout.dart';
import '../../../services/presentation/screens/layout/admin_main_layout.dart';
import 'package:forja_trabajo/features/auth/presentation/providers/auth_provider.dart';
import 'package:forja_trabajo/core/theme/app_theme.dart';
import 'register_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _showPassword = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      FocusScope.of(context).unfocus();
      ref.read(authProvider.notifier).loginUser(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState.status == 'loading';

ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.status == 'error') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.errorMessage), backgroundColor: AppTheme.dangerRose),
        );
      } 
      // 👇 ¡EL SECRETO ESTÁ AQUÍ! Le decimos que espere a que next.user ya tenga datos
      else if (next.status == 'authenticated' && next.user != null) { 
        
        Widget nextScreen;
        
        // Como ya sabemos que no es null, podemos leer el rol seguros
        final role = next.user!.role.toLowerCase().trim();
        
        debugPrint('🚀 AHORA SÍ, ROL DETECTADO: "$role"');

        if (role == 'admin' || role == 'administrador') {
          nextScreen = const AdminMainLayout(); // Tu panel de admin
        } else if (role == 'worker' || role == 'trabajador') {
          nextScreen = const WorkerMainLayout(); // Tu panel de trabajador
        } else {
          nextScreen = const ClientMainLayout(); // El de cliente
        }

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => nextScreen),
          (route) => false, 
        );
      }
    });

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Stack(
        children: [
          Positioned(top: -50, right: -50, child: _buildBlurCircle()),
          Positioned(bottom: -50, left: -50, child: _buildBlurCircle(size: 250)),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(Icons.handyman_outlined, size: 48, color: AppTheme.primaryColor),
                      ),
                      const SizedBox(height: 24),
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.textColor),
                          children: const [
                            TextSpan(text: 'Bienvenido a \n'),
                            TextSpan(text: 'Forja Trabajo', style: TextStyle(color: AppTheme.primaryColor)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                      _buildLabel('Email'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _emailController,
                        decoration: _buildInputDecoration('ejemplo@correo.com'),
                        validator: (value) => value!.isEmpty ? 'Ingresa tu correo' : null,
                      ),
                      const SizedBox(height: 20),
                      _buildLabel('Contraseña'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: !_showPassword,
                        decoration: _buildInputDecoration('••••••••').copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility),
                            onPressed: () => setState(() => _showPassword = !_showPassword),
                          ),
                        ),
                        validator: (value) => value!.isEmpty ? 'Ingresa tu contraseña' : null,
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: isLoading 
                            ? const CircularProgressIndicator(color: Colors.white) 
                            : const Text('Iniciar Sesión', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterScreen())),
                        child: const Text('¿No tienes una cuenta? Regístrate', style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) => Align(alignment: Alignment.centerLeft, child: Text(text, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey.shade700)));

  InputDecoration _buildInputDecoration(String hint) => InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2)),
  );

  Widget _buildBlurCircle({double size = 200}) => Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, color: AppTheme.primaryColor.withValues(alpha: 0.08)), child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50), child: Container(color: Colors.transparent)));
}