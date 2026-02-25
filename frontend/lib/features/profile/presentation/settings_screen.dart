import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forja_trabajo/features/services/presentation/screens/client/edit_profile_screen.dart';
import 'package:forja_trabajo/features/auth/presentation/providers/auth_provider.dart';
import 'package:forja_trabajo/features/auth/presentation/screens/login_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  // Estados temporales para los interruptores
  bool _notificationsEnabled = true;
  bool _locationEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Fondo gris muy clarito
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          "Configuración",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 20),
          
          // --- SECCIÓN: CUENTA ---
          _buildSectionHeader("Cuenta"),
          _buildListTile(
            icon: Icons.person_outline,
            title: "Editar Perfil",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const EditProfileScreen()),
              );
              print("Ir a editar perfil");
            },
          ),
          _buildListTile(
            icon: Icons.lock_outline,
            title: "Cambiar Contraseña",
            onTap: () {},
          ),
          
          const SizedBox(height: 24),
          
          // --- SECCIÓN: PREFERENCIAS ---
          _buildSectionHeader("Preferencias"),
          _buildSwitchTile(
            icon: Icons.notifications_none,
            title: "Notificaciones Push",
            value: _notificationsEnabled,
            onChanged: (val) => setState(() => _notificationsEnabled = val),
          ),
          _buildSwitchTile(
            icon: Icons.location_on_outlined,
            title: "Servicios cerca de mí",
            value: _locationEnabled,
            onChanged: (val) => setState(() => _locationEnabled = val),
          ),
          
          const SizedBox(height: 24),
          
          // --- SECCIÓN: SOPORTE ---
          _buildSectionHeader("Soporte y Legal"),
          _buildListTile(
            icon: Icons.help_outline,
            title: "Centro de Ayuda",
            onTap: () {},
          ),
          _buildListTile(
            icon: Icons.description_outlined,
            title: "Términos y Condiciones",
            onTap: () {},
          ),
          
          const SizedBox(height: 40),
          
          // --- ZONA DE PELIGRO ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: ElevatedButton.icon(
              onPressed: () {
               _showLogoutConfirmation(context, ref);
              },
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text(
                "Cerrar Sesión", 
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16)
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade50, // Rojito claro de fondo
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: () {},
              child: const Text("Eliminar cuenta", style: TextStyle(color: Colors.grey)),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // --- WIDGETS REUTILIZABLES PARA ESTA PANTALLA ---

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade600,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildListTile({required IconData icon, required String title, required VoidCallback onTap}) {
    return Container(
      color: Colors.white,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 24.0),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: const Color(0xFF4F46E5), size: 20),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }

  Widget _buildSwitchTile({required IconData icon, required String title, required bool value, required ValueChanged<bool> onChanged}) {
    return Container(
      color: Colors.white,
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 24.0),
        secondary: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: const Color(0xFF4F46E5), size: 20),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        activeColor: const Color(0xFF4F46E5),
        value: value,
        onChanged: onChanged,
      ),
    );
  }
  void _showLogoutConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange),
              SizedBox(width: 10),
              Text("¿Cerrar sesión?", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          content: const Text(
            "¿Estás seguro de que deseas salir de tu cuenta? Tendrás que volver a ingresar tus credenciales la próxima vez.",
            style: TextStyle(color: Colors.black87),
          ),
          actions: [
            // Botón de Cancelar
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Solo cierra el diálogo
              },
              child: const Text("Cancelar", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            ),
            // Botón de Confirmar Salida
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(); // 1. Cerramos el diálogo primero
                ref.read(authProvider.notifier).logoutUser(); // 2. Ejecutamos el cierre de sesión
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text("Sí, salir", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }
}
