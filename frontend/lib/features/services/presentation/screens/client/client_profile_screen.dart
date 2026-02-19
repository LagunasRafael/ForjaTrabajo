import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forja_trabajo/core/theme/app_theme.dart';
import 'package:forja_trabajo/features/auth/presentation/providers/auth_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

class ClientProfileScreen extends ConsumerWidget {
  const ClientProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(user?.fullName ?? "Cliente", user?.email ?? "", "Cliente"),
            const SizedBox(height: 30),
            _buildMenuCard([
              _buildOption(LucideIcons.user, 'Mi Información', () {}),
              _buildOption(LucideIcons.shoppingBag, 'Mis Solicitudes de Servicio', () {}),
              _buildOption(LucideIcons.creditCard, 'Métodos de Pago', () {}),
              _buildOption(LucideIcons.bell, 'Notificaciones', () {}),
            ]),
            const SizedBox(height: 32),
            _buildLogoutButton(context, ref),
          ],
        ),
      ),
    );
  }

  // --- WIDGETS REUTILIZABLES ---
  Widget _buildHeader(String name, String email, String role) {
    return Container(
      padding: const EdgeInsets.only(top: 60, bottom: 30),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
            child: const Icon(LucideIcons.user, size: 50, color: AppTheme.primaryColor),
          ),
          const SizedBox(height: 16),
          Text(name, style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold)),
          Text(email, style: GoogleFonts.inter(color: Colors.grey)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(role.toUpperCase(), style: const TextStyle(color: AppTheme.primaryColor, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
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
      trailing: const Icon(Icons.chevron_right, size: 20),
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