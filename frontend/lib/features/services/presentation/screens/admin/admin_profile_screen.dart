import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forja_trabajo/core/theme/app_theme.dart';
import 'package:forja_trabajo/features/auth/presentation/providers/auth_provider.dart';
import 'package:forja_trabajo/features/auth/presentation/screens/login_screen.dart'; // Asegúrate de que esta ruta sea correcta
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

// 👇 IMPORTANTE: Agregamos el import de tu pantalla de categorías. 
// Ajusta la cantidad de "../" si tu carpeta está en otro nivel.
import '../../../../services/presentation/screens/admin/manage_categories_screen.dart'; 

class AdminProfileScreen extends ConsumerWidget {
  const AdminProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Reutilizamos tu Header que sí funciona
            _buildHeader(
              user?.fullName ?? "Administrador", 
              user?.email ?? "", 
              user?.role ?? "Admin"
            ),
            const SizedBox(height: 30),
            
            // Opciones de Administrador con tu diseño de MenuCard
            _buildMenuCard([
              _buildOption(LucideIcons.users, 'Gestionar Usuarios', () {
                // Navegación a gestión de usuarios
              }),
              _buildOption(LucideIcons.layoutGrid, 'Gestionar Categorías', () {
                // 🚀 NAVEGACIÓN CONECTADA AQUÍ
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ManageCategoriesScreen()
                  ),
                );
              }),
              _buildOption(LucideIcons.database, 'Configuración Base', () {}),
              _buildOption(LucideIcons.settings, 'Ajustes del Sistema', () {}),
            ]),
            
            const SizedBox(height: 32),
            
            // El botón de cerrar sesión idéntico al del cliente
            _buildLogoutButton(context, ref),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // --- WIDGETS BASADOS EN TU DISEÑO FUNCIONAL ---

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
            child: const Icon(LucideIcons.shieldCheck, size: 50, color: AppTheme.primaryColor),
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
            child: Text(
              role.toUpperCase(), 
              style: const TextStyle(color: AppTheme.primaryColor, fontSize: 10, fontWeight: FontWeight.bold)
            ),
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
          // 1. Limpiamos sesión
          await ref.read(authProvider.notifier).logoutUser();

          // 2. Navegación forzada al LoginScreen
          if (context.mounted) {
            Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const LoginScreen()),
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
        label: Text(
          "Cerrar Sesión", 
          style: GoogleFonts.inter(color: AppTheme.dangerRose, fontWeight: FontWeight.bold)
        ),
      ),
    );
  }
}