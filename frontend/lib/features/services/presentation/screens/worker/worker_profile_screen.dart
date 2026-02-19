import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forja_trabajo/core/theme/app_theme.dart';
import 'package:forja_trabajo/features/auth/presentation/providers/auth_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

// 👇 RUTAS CORREGIDAS

class WorkerProfileScreen extends ConsumerWidget {
  const WorkerProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text('Mi Perfil de Trabajador', 
          style: GoogleFonts.inter(color: AppTheme.textColor, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 24),
            _buildAvatar(user?.fullName ?? "Cargando..."),
            const SizedBox(height: 16),
            Text(user?.fullName ?? "...", style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold)),
            _buildRoleBadge("Trabajador"),
            const SizedBox(height: 32),
            _buildMenuCard([
              _buildOption(LucideIcons.briefcase, 'Mi Portafolio', () {}),
              _buildOption(LucideIcons.star, 'Mis Reseñas', () {}),
              _buildOption(LucideIcons.history, 'Historial de Trabajos', () {}),
            ]),
            const SizedBox(height: 32),
            _buildLogoutButton(context, ref),
          ],
        ),
      ),
    );
  }

  // --- MÉTODOS DE APOYO (IDÉNTICOS PARA LOS 3) ---
  Widget _buildAvatar(String name) {
    return Center(
      child: CircleAvatar(
        radius: 60,
        backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
        child: const Icon(LucideIcons.user, size: 60, color: AppTheme.primaryColor),
      ),
    );
  }

  Widget _buildRoleBadge(String label) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.successEmerald.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label.toUpperCase(), 
        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.successEmerald)),
    );
  }

  Widget _buildMenuCard(List<Widget> children) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 20)],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildOption(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryColor, size: 20),
      title: Text(title, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w500)),
      trailing: const Icon(LucideIcons.chevronRight, size: 20),
      onTap: onTap,
    );
  }

  Widget _buildLogoutButton(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: OutlinedButton.icon(
        onPressed: () async {
          // 1. Llamamos a la lógica de limpieza que pusimos arriba
          await ref.read(authProvider.notifier).logoutUser();

          // 2. Navegamos al Login y BORRAMOS todas las pantallas anteriores
          // Esto hace que la app "olvide" que estaba en el perfil
          if (context.mounted) {
            Navigator.pushNamedAndRemoveUntil(
              context, 
              '/login', // Reemplaza por el nombre de tu ruta de Login o RoleSelection
              (route) => false, 
            );
          }
        },
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 56),
          side: const BorderSide(color: AppTheme.dangerRose),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        icon: const Icon(LucideIcons.logOut, color: AppTheme.dangerRose),
        label: Text("Cerrar Sesión", style: GoogleFonts.inter(color: AppTheme.dangerRose, fontWeight: FontWeight.bold)),
      ),
    );
  }
}