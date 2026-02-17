import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/theme/app_theme.dart';
import '../widgets/role_card.dart';

// OJO: Importa aquí tu LoginScreen para poder navegar a ella
import 'login_screen.dart'; 

enum UserRole { client, worker, none }

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  UserRole _selectedRole = UserRole.none;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Stack(
        children: [
          // Fondo con gradiente sutil
          Positioned(
            top: 0, left: 0, right: 0, height: 300,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppTheme.primaryColor.withOpacity(0.08),
                    AppTheme.backgroundColor,
                  ],
                ),
              ),
            ),
          ),
          
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  
                  // Logo Rotado
                  Transform.rotate(
                    angle: 0.05, 
                    child: Container(
                      width: 64, height: 64,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(LucideIcons.hammer, color: Colors.white, size: 32),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Título
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: GoogleFonts.inter(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textColor,
                        height: 1.2,
                      ),
                      children: [
                        const TextSpan(text: '¿Cómo quieres usar\n'),
                        const TextSpan(
                          text: 'Forja Trabajo',
                          style: TextStyle(color: AppTheme.primaryColor),
                        ),
                        const TextSpan(text: ' hoy?'),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  Text(
                    'Elige tu perfil para comenzar una experiencia personalizada.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      color: AppTheme.subtitleColor,
                      height: 1.5,
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Cards de Selección
                  RoleCard(
                    title: 'Soy Cliente',
                    description: 'Busco contratar un servicio o profesional.',
                    icon: LucideIcons.userCheck,
                    imageUrl: 'https://images.unsplash.com/photo-1521737711867-e3b97375f902?q=80&w=500&auto=format&fit=crop',
                    isSelected: _selectedRole == UserRole.client,
                    onTap: () => setState(() => _selectedRole = UserRole.client),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  RoleCard(
                    title: 'Soy Trabajador',
                    description: 'Quiero ofrecer mis servicios y ganar dinero.',
                    icon: LucideIcons.briefcase,
                    imageUrl: 'https://images.unsplash.com/photo-1504384308090-c894fdcc538d?q=80&w=500&auto=format&fit=crop',
                    isSelected: _selectedRole == UserRole.worker,
                    onTap: () => setState(() => _selectedRole = UserRole.worker),
                  ),
                  
                  const SizedBox(height: 40),
                  Divider(color: Colors.grey.withOpacity(0.2)),
                  const SizedBox(height: 24),
                  
                  Text(
                    '¿Ya tienes una cuenta?',
                    style: const TextStyle(color: AppTheme.subtitleColor, fontSize: 14),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // BOTÓN CONECTADO AL LOGIN
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton(
                      // AQUÍ HACEMOS LA NAVEGACIÓN A TU LOGIN
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const LoginScreen()),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey.shade200),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        backgroundColor: Colors.white,
                      ),
                      child: const Text(
                        'Inicia sesión',
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  Text(
                    'Al continuar, aceptas nuestros Términos y Política de Privacidad.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}