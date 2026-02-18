import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../services/presentation/screens/main_client_screen.dart';
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
  
  // Nuevo estado para mostrar/ocultar contraseña
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
          SnackBar(
            content: Text(next.errorMessage),
            backgroundColor: AppTheme.dangerRose,
          ),
        );
      } else if (next.status == 'authenticated') {
        // Mensaje de éxito
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Bienvenido a Forja Trabajo!'),
            backgroundColor: AppTheme.successEmerald,
          ),
        );
        
        // 🚀 MAGIA DE NAVEGACIÓN: Lo mandamos al Home y destruimos la pantalla de Login
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainClientScreen()),
        );
      }
    });

    return Scaffold(
      // Usamos el fondo claro para hacer juego con el diseño
      backgroundColor: AppTheme.backgroundColor,
      body: Stack(
        children: [
          // --- DIFUMINADOS DECORATIVOS (Blur Elements) ---
          Positioned(
            top: -50,
            right: -50,
            child: _buildBlurCircle(),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: _buildBlurCircle(size: 250),
          ),

          // --- CONTENIDO PRINCIPAL ---
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // --- LOGO ---
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.handyman_outlined,
                          size: 48,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // --- TÍTULO ---
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: GoogleFonts.inter(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textColor,
                            height: 1.2,
                          ),
                          children: const [
                            TextSpan(text: 'Bienvenido a \n'),
                            TextSpan(
                              text: 'Forja Trabajo',
                              style: TextStyle(color: AppTheme.primaryColor),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Conectando talento local con grandes oportunidades',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppTheme.subtitleColor,
                        ),
                      ),
                      const SizedBox(height: 40),

                      // --- CAMPO EMAIL ---
                      _buildLabel('Email'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: GoogleFonts.inter(color: AppTheme.textColor),
                        decoration: _buildInputDecoration('ejemplo@correo.com'),
                        validator: (value) => value!.isEmpty ? 'Ingresa tu correo' : null,
                      ),
                      const SizedBox(height: 20),

                      // --- CAMPO CONTRASEÑA ---
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildLabel('Contraseña'),
                          TextButton(
                            onPressed: () {}, // TODO: Recuperar contraseña
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              '¿Olvidaste tu contraseña?',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: !_showPassword,
                        style: GoogleFonts.inter(color: AppTheme.textColor),
                        decoration: _buildInputDecoration('••••••••').copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(
                              _showPassword ? Icons.visibility_off : Icons.visibility,
                              color: Colors.grey.shade400,
                            ),
                            onPressed: () {
                              setState(() {
                                _showPassword = !_showPassword;
                              });
                            },
                          ),
                        ),
                        validator: (value) => value!.isEmpty ? 'Ingresa tu contraseña' : null,
                      ),
                      const SizedBox(height: 32),

                      // --- BOTÓN PRINCIPAL ---
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            elevation: 8,
                            shadowColor: AppTheme.primaryColor.withOpacity(0.4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : Text(
                                  'Iniciar Sesión',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // --- DIVISOR SOCIAL ---
                      Row(
                        children: [
                          Expanded(child: Divider(color: Colors.grey.shade300)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'O CONTINÚA CON',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade400,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                          Expanded(child: Divider(color: Colors.grey.shade300)),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // --- BOTONES SOCIALES ---
                      Row(
                        children: [
                          Expanded(child: _buildSocialButton('Google', Icons.g_mobiledata)),
                          const SizedBox(width: 16),
                          Expanded(child: _buildSocialButton('Apple', Icons.apple)),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // --- REGÍSTRATE ---
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '¿No tienes una cuenta? ',
                            style: GoogleFonts.inter(color: Colors.grey.shade600, fontSize: 14),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const RegisterScreen()),
                              );
                            },
                            child: Text(
                              'Regístrate',
                              style: GoogleFonts.inter(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
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

  // --- WIDGETS DE AYUDA (Para mantener el build limpio) ---

  Widget _buildLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade700,
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.grey),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
      ),
    );
  }

  Widget _buildSocialButton(String label, IconData icon) {
    return SizedBox(
      height: 56,
      child: OutlinedButton.icon(
        onPressed: () {},
        icon: Icon(icon, color: AppTheme.textColor, size: 28),
        label: Text(
          label,
          style: GoogleFonts.inter(
            color: AppTheme.textColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          side: BorderSide(color: Colors.grey.shade200),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  Widget _buildBlurCircle({double size = 200}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppTheme.primaryColor.withOpacity(0.08),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
        child: Container(color: Colors.transparent),
      ),
    );
  }
}