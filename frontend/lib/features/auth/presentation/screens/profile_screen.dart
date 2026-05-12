import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';
import 'role_selection_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Escuchamos el estado completo de Autenticación
    final authState = ref.watch(authProvider);
    final user = authState.user;

    final theme = Theme.of(context);

    // 2. Extraemos los datos dinámicos (con valores por defecto si aún está cargando)
    final String userName = user?.fullName ?? "Cargando...";
    final String userEmail = user?.email ?? "Cargando...";
    final String userRole = user?.role ?? "...";
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Mi Perfil',
          style: GoogleFonts.inter(
            color: theme.textTheme.titleLarge?.color ?? AppTheme.textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 24),
            // --- FOTO DE PERFIL Y DATOS BÁSICOS ---
            Center(
              child: Stack(
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      border: Border.all(
                          color: AppTheme.primaryColor.withOpacity(0.2),
                          width: 4),
                    ),
                    child: const Center(
                      child: Icon(LucideIcons.user,
                          size: 60, color: AppTheme.primaryColor),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: AppTheme.primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(LucideIcons.pencil,
                          color: Colors.white, size: 16),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              userName,
              style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color:
                      theme.textTheme.titleLarge?.color ?? AppTheme.textColor),
            ),
            const SizedBox(height: 4),
            // 📍 NUEVO: LA UBICACIÓN MÁGICA
            if (user?.city != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(LucideIcons.mapPin,
                      size: 14, color: AppTheme.primaryColor),
                  const SizedBox(width: 4),
                  Text(
                    user!.city!, // Aquí dirá ej. "Ciudad Hidalgo, Michoacán"
                    style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.primaryColor),
                  ),
                ],
              ),
              const SizedBox(height: 4),
            ],
            Text(
              userEmail,
              style: GoogleFonts.inter(
                  fontSize: 14, color: AppTheme.subtitleColor),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.successEmerald.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                userRole.toUpperCase(),
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.successEmerald,
                ),
              ),
            ),
            const SizedBox(height: 40),

            // --- OPCIONES DEL PERFIL ---
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 20,
                      offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                children: [
                  _buildProfileOption(
                    icon: LucideIcons.userCog,
                    title: 'Editar Datos Personales',
                    onTap: () {},
                    theme: theme,
                  ),
                  _buildDivider(theme),
                  _buildProfileOption(
                    icon: LucideIcons.lock,
                    title: 'Cambiar Contraseña',
                    onTap: () {},
                    theme: theme,
                  ),
                  _buildDivider(theme),
                  _buildProfileOption(
                    icon: LucideIcons.creditCard,
                    title: 'Métodos de Pago',
                    onTap: () {},
                    theme: theme,
                  ),
                  _buildDivider(theme),
                  _buildProfileOption(
                    icon: LucideIcons.helpCircle,
                    title: 'Soporte y Ayuda',
                    onTap: () {},
                    theme: theme,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // --- BOTÓN DE CERRAR SESIÓN ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton.icon(
                  onPressed: () {
                    // LÓGICA DE CIERRE DE SESIÓN
                    ref.read(authProvider.notifier).logoutUser();
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const RoleSelectionScreen()),
                      (route) => false,
                    );
                  },
                  icon: const Icon(LucideIcons.logOut,
                      color: AppTheme.dangerRose),
                  label: Text(
                    'Cerrar Sesión',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.dangerRose,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(
                        color: AppTheme.dangerRose, width: 1.5),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // Widgets de ayuda para mantener el código limpio
  Widget _buildProfileOption(
      {required IconData icon,
      required String title,
      required VoidCallback onTap,
      required ThemeData theme}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            shape: BoxShape.circle),
        child: Icon(icon, color: AppTheme.primaryColor, size: 20),
      ),
      title: Text(title,
          style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              color: theme.textTheme.bodyLarge?.color ?? AppTheme.textColor,
              fontSize: 15)),
      trailing:
          const Icon(LucideIcons.chevronRight, color: Colors.grey, size: 20),
      onTap: onTap,
    );
  }

  Widget _buildDivider(ThemeData theme) {
    return Divider(
        height: 1,
        thickness: 1,
        color: theme.brightness == Brightness.dark
            ? const Color(0xFF334155)
            : Colors.grey.shade100,
        indent: 70,
        endIndent: 24);
  }
}
