import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:forja_trabajo/features/auth/presentation/providers/auth_provider.dart';
import 'package:forja_trabajo/features/profile/presentation/screens/legal_document_screen.dart';
import 'verification_screen.dart';

import '../../../../core/theme/app_theme.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controladores de texto
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  late TapGestureRecognizer _termsRecognizer;
  late TapGestureRecognizer _privacyRecognizer;

  // Estado del formulario
  bool _isWorker = false; // false = Cliente, true = Trabajador
  bool _showPassword = false;
  bool _acceptTerms = false;

  @override
  void initState() {
    super.initState();
    _termsRecognizer = TapGestureRecognizer()
      ..onTap = () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const LegalDocumentScreen(
              type: LegalDocumentType.termsAndConditions,
            ),
          ),
        );
      };
    _privacyRecognizer = TapGestureRecognizer()
      ..onTap = () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const LegalDocumentScreen(
              type: LegalDocumentType.privacyPolicy,
            ),
          ),
        );
      };
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _termsRecognizer.dispose();
    _privacyRecognizer.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate() && _acceptTerms) {
      FocusScope.of(context).unfocus();

      final roleString = _isWorker
          ? 'worker'
          : 'client'; // O los nombres exactos que use tu amigo en su enum Role

      // ¡Disparamos la petición al backend!
      ref.read(authProvider.notifier).registerUser(
            fullName: _nameController.text.trim(),
            email: _emailController.text.trim(),
            phone: _phoneController.text.trim(),
            password: _passwordController.text.trim(),
            role: roleString,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. Escuchamos si está cargando para bloquear el botón
    final authState = ref.watch(authProvider);
    final isLoading = authState.status == 'loading';

    // 2. Escuchamos eventos de éxito o error
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.status == 'error') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage),
            backgroundColor: AppTheme.dangerRose,
          ),
        );
      } else if (next.status == 'registered') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('¡Cuenta creada con éxito! Por favor verifica tu correo.'),
            backgroundColor: AppTheme.successEmerald,
          ),
        );
        // Lo mandamos directo a la pantalla de Verificación
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                VerificationScreen(email: _emailController.text.trim()),
          ),
        );
      }
    });
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: theme.iconTheme.color),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Crear Cuenta',
          style: GoogleFonts.inter(
            color: theme.textTheme.titleLarge?.color,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // --- SELECTOR DE ROL (Role Toggle) ---
                _buildRoleToggle(),
                const SizedBox(height: 32),

                // --- CAMPOS DE TEXTO ---
                _buildTextField(
                  label: 'Nombre Completo',
                  hint: 'Ej. Juan Pérez',
                  icon: Icons.person_outline,
                  controller: _nameController,
                  validator: (v) => v!.isEmpty ? 'Ingresa tu nombre' : null,
                ),
                const SizedBox(height: 20),

                _buildTextField(
                  label: 'Correo Electrónico',
                  hint: 'correo@ejemplo.com',
                  icon: Icons.mail_outline,
                  keyboardType: TextInputType.emailAddress,
                  controller: _emailController,
                  validator: (v) =>
                      !v!.contains('@') ? 'Correo no válido' : null,
                ),
                const SizedBox(height: 20),

                _buildTextField(
                  label: 'Teléfono',
                  hint: '+52 123 456 7890',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  controller: _phoneController,
                  validator: (v) => v!.isEmpty ? 'Ingresa un teléfono' : null,
                ),
                const SizedBox(height: 20),

                _buildTextField(
                  label: 'Contraseña',
                  hint: '••••••••',
                  icon: Icons.lock_outline,
                  controller: _passwordController,
                  isPassword: true,
                  validator: (v) =>
                      v!.length < 6 ? 'Mínimo 6 caracteres' : null,
                ),
                const SizedBox(height: 24),

                // --- TÉRMINOS Y CONDICIONES ---
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Checkbox(
                        value: _acceptTerms,
                        activeColor: AppTheme.primaryColor,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4)),
                        onChanged: (value) {
                          setState(() => _acceptTerms = value ?? false);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: GoogleFonts.inter(
                              color: theme.colorScheme.onSurface.withOpacity(0.6),
                              fontSize: 13,
                              height: 1.4),
                          children: [
                            const TextSpan(text: 'Acepto los '),
                            TextSpan(
                                text: 'Términos y Condiciones',
                                recognizer: _termsRecognizer,
                                style: const TextStyle(
                                    color: AppTheme.primaryColor,
                                    fontWeight: FontWeight.bold)),
                            const TextSpan(text: ' y la '),
                            TextSpan(
                                text: 'Política de Privacidad',
                                recognizer: _privacyRecognizer,
                                style: const TextStyle(
                                    color: AppTheme.primaryColor,
                                    fontWeight: FontWeight.bold)),
                            const TextSpan(text: ' de Forja Trabajo.'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // --- BOTÓN DE REGISTRO ---
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    // Si está cargando o no aceptó términos, bloqueamos el botón
                    onPressed: (_acceptTerms && !isLoading) ? _submit : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _acceptTerms
                          ? AppTheme.primaryColor
                          : theme.colorScheme.onSurface.withOpacity(0.38),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    // Mostramos la rueda girando si isLoading es true
                    child: isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : Text(
                            'Crear Cuenta',
                            style: GoogleFonts.inter(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: _acceptTerms
                                  ? Colors.white // Letras blancas
                                  : theme.colorScheme.onSurface.withOpacity(0.5),
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 24),

                // --- IR AL LOGIN ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '¿Ya tienes una cuenta? ',
                      style: GoogleFonts.inter(
                          color: theme.colorScheme.onSurface.withOpacity(0.6), fontSize: 14),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Text(
                        'Inicia sesión',
                        style: GoogleFonts.inter(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- WIDGETS CONSTRUCTORES ---

  Widget _buildRoleToggle() {
    final theme = Theme.of(context);

    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isWorker = false),
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: !_isWorker ? theme.cardColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: !_isWorker
                      ? [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2))
                        ]
                      : null,
                ),
                margin: const EdgeInsets.all(4),
                child: Text(
                  'Soy Cliente',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    color: !_isWorker
                        ? AppTheme.primaryColor
                        : theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isWorker = true),
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _isWorker ? theme.cardColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: _isWorker
                      ? [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2))
                        ]
                      : null,
                ),
                margin: const EdgeInsets.all(4),
                child: Text(
                  'Soy Trabajador',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    color: _isWorker
                        ? AppTheme.primaryColor
                        : theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface.withOpacity(0.6)),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: isPassword && !_showPassword,
          keyboardType: keyboardType,
          style: GoogleFonts.inter(color: theme.textTheme.bodyLarge?.color),
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5)),
            filled: true,
            fillColor: theme.cardColor,
            prefixIcon: Icon(icon, color: theme.colorScheme.onSurface.withOpacity(0.38)),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                        _showPassword ? Icons.visibility_off : Icons.visibility,
                        color: theme.colorScheme.onSurface.withOpacity(0.38)),
                    onPressed: () =>
                        setState(() => _showPassword = !_showPassword),
                  )
                : null,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                    color:
                        theme.colorScheme.outline)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                    color:
                        theme.colorScheme.outline)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide:
                    const BorderSide(color: AppTheme.primaryColor, width: 2)),
            errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppTheme.dangerRose)),
          ),
        ),
      ],
    );
  }
}
