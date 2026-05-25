import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:forja_trabajo/core/network/notification_service.dart';
import 'package:forja_trabajo/features/services/presentation/screens/client/edit_profile_screen.dart';
import 'package:forja_trabajo/features/auth/presentation/providers/auth_provider.dart';
import 'package:forja_trabajo/features/auth/presentation/screens/login_screen.dart';
import 'package:forja_trabajo/features/profile/presentation/screens/legal_document_screen.dart';
import 'package:forja_trabajo/core/theme/theme_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
    });
  }

  Future<void> _saveNotificationPreference(bool value) async {
    setState(() => _isLoading = true);
    try {
      if (value) {
        final token = await NotificationService().enableNotifications();
        if (token != null && token.isNotEmpty) {
          final dataSource = ref.read(authDataSourceProvider);
          await dataSource.updateFcmToken(token);
        }
      } else {
        await NotificationService().disableNotifications();
      }
      setState(() => _notificationsEnabled = value);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cambiar notificaciones: $e')),
        );
      }
      setState(() => _notificationsEnabled = !value);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    final isDarkMode = themeMode == ThemeMode.dark;

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
            value: _notificationsEnabled,
            onChanged: _isLoading ? null : _saveNotificationPreference,
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
                _showLogoutConfirmation(context, ref);
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

  void _showLogoutConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange),
              SizedBox(width: 10),
              Text("¿Cerrar sesión?",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          content: Text(
            "¿Estás seguro de que deseas salir de tu cuenta? Tendrás que volver a ingresar tus credenciales la próxima vez.",
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          ),
          actions: [
            // Botón de Cancelar
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Solo cierra el diálogo
              },
              child: const Text("Cancelar",
                  style: TextStyle(
                      color: Colors.grey, fontWeight: FontWeight.bold)),
            ),
            // Botón de Confirmar Salida
            ElevatedButton(
              onPressed: () async {
                Navigator.of(dialogContext)
                    .pop(); // 1. Cerramos el diálogo primero
                await ref
                    .read(authProvider.notifier)
                    .logoutUser(); // 2. Ejecutamos el cierre de sesión
                if (context.mounted) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const LoginScreen()),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text("Sí, salir",
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }
}
