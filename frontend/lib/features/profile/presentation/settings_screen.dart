import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forja_trabajo/core/network/notification_controller.dart';
import 'package:forja_trabajo/features/services/presentation/screens/client/edit_profile_screen.dart';
import 'package:forja_trabajo/features/auth/presentation/providers/auth_provider.dart';
import 'package:forja_trabajo/features/auth/presentation/screens/login_screen.dart';
import 'package:forja_trabajo/features/profile/presentation/screens/legal_document_screen.dart';
import 'package:forja_trabajo/features/auth/presentation/widgets/profile_shared_widgets.dart';
import 'package:forja_trabajo/core/theme/theme_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    final isDarkMode = themeMode == ThemeMode.dark;
    final notificationsEnabled = ref.watch(notificationControllerProvider);

    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        iconTheme: theme.iconTheme,
        title: Text(
          "Configuración",
          style:
              theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
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
                MaterialPageRoute(
                    builder: (context) => const EditProfileScreen()),
              );
            },
          ),

          const SizedBox(height: 24),

          // --- SECCIÓN: PREFERENCIAS ---
          _buildSectionHeader("Preferencias"),
          _buildSwitchTile(
            icon: Icons.dark_mode_outlined,
            title: "Modo Oscuro",
            value: isDarkMode,
            onChanged: (val) {
              ref.read(themeProvider.notifier).toggleTheme(val);
            },
          ),
          _buildSwitchTile(
            icon: Icons.notifications_none,
            title: "Notificaciones Push",
            value: notificationsEnabled,
            onChanged: _isLoading
                ? null
                : (val) async {
                    setState(() => _isLoading = true);
                    try {
                      final controller =
                          ref.read(notificationControllerProvider.notifier);
                      if (val) {
                        final role = ref.read(authProvider).user?.role;
                        await controller.enable(userRole: role);
                      } else {
                        await controller.disable();
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content:
                                  Text('Error al cambiar notificaciones: $e')),
                        );
                      }
                    } finally {
                      if (mounted) setState(() => _isLoading = false);
                    }
                  },
          ),

          const SizedBox(height: 24),

          // --- SECCIÓN: SOPORTE ---
          _buildSectionHeader("Soporte y Legal"),
          _buildListTile(
            icon: Icons.help_outline,
            title: "Contactar Soporte",
            onTap: () {
              // Ejemplo: abrir whatsapp o correo
              _launchURL("mailto:forjatrabajo@gmail.com?subject=Soporte%20App");
            },
          ),
          _buildListTile(
            icon: Icons.description_outlined,
            title: "Términos y Condiciones",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const LegalDocumentScreen(
                    type: LegalDocumentType.termsAndConditions,
                  ),
                ),
              );
            },
          ),
          _buildListTile(
            icon: Icons.privacy_tip_outlined,
            title: "Aviso de Privacidad",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const LegalDocumentScreen(
                    type: LegalDocumentType.privacyPolicy,
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 40),

          // --- ZONA DE PELIGRO ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: ElevatedButton.icon(
              onPressed: () {
                showModernLogoutDialog(context, ref);
              },
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text("Cerrar Sesión",
                  style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.errorContainer,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Future<void> _launchURL(String urlString) async {
    final url = Uri.parse(urlString);
    if (!await launchUrl(url)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir el enlace')),
        );
      }
    }
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
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildListTile(
      {required IconData icon,
      required String title,
      required VoidCallback onTap}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      color: theme.cardColor,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 24.0),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: const Color(0xFF4F46E5), size: 20),
        ),
        title: Text(title,
            style: theme.textTheme.bodyLarge
                ?.copyWith(fontWeight: FontWeight.w500)),
        trailing:
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }

  Widget _buildSwitchTile(
      {required IconData icon,
      required String title,
      required bool value,
      required ValueChanged<bool>? onChanged}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      color: theme.cardColor,
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 24.0),
        secondary: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: const Color(0xFF4F46E5), size: 20),
        ),
        title: Text(title,
            style: theme.textTheme.bodyLarge
                ?.copyWith(fontWeight: FontWeight.w500)),
        activeColor: const Color(0xFF4F46E5),
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}
