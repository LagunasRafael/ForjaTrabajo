import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forja_trabajo/core/theme/app_theme.dart';
import 'package:forja_trabajo/features/auth/presentation/providers/auth_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:forja_trabajo/features/auth/presentation/widgets/profile_shared_widgets.dart';
import 'package:forja_trabajo/features/services/presentation/screens/client/edit_profile_screen.dart';
import 'package:forja_trabajo/features/profile/presentation/settings_screen.dart';
import 'package:forja_trabajo/features/profile/presentation/settings_screen.dart';

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
            // Pasamos los datos al header
            _buildHeader(
              user?.fullName ?? "Cliente",
              user?.email ?? "",
              "Cliente",
              user?.profilePictureUrl,
              user?.city,
              ref
            ),
            const SizedBox(height: 30),
            
            // MENÚ DE OPCIONES
            ProfileMenuCard(
              children: [
                ProfileMenuOption(icon: LucideIcons.user, title: 'Mi Información', onTap: () {}),
                ProfileMenuOption(icon: LucideIcons.shoppingBag, title: 'Mis Solicitudes de Servicio', onTap: () {}),
                ProfileMenuOption(icon: LucideIcons.creditCard, title: 'Métodos de Pago', onTap: () {}),
                ProfileMenuOption(icon: LucideIcons.bell, title: 'Notificaciones', onTap: () {}),
                ProfileMenuOption(
                  icon: LucideIcons.pencil,
                  title: 'Editar Perfil',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const EditProfileScreen()),
                    );
                  },
                ),
                ProfileMenuOption(
                  icon: LucideIcons.settings,
                  title: 'Configuración',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SettingsScreen()),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 32),
            const ProfileLogoutButton(),
            const SizedBox(height: 40), // Espacio extra al final
          ],
        ),
      ),
    );
  }

  // 👇 MOVIDO DENTRO DE LA CLASE PARA QUE FUNCIONE CORRECTAMENTE
  Widget _buildHeader(String name, String email, String role, String? imageUrl, String? city, WidgetRef ref) {
    return Container(
      width: double.infinity, // Asegura que ocupe todo el ancho
      padding: const EdgeInsets.only(top: 60, bottom: 30),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          EditableProfileAvatar(
            imageUrl: imageUrl,
            radius: 50,
          ),
          const SizedBox(height: 16),
          Text(name, style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold)),
          Text(email, style: GoogleFonts.inter(color: Colors.grey)),
          const SizedBox(height: 12),
          
          // UBICACIÓN INTERACTIVA
          InkWell(
            onTap: () async {
              await ref.read(authProvider.notifier).autoUpdateLocation();
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    LucideIcons.mapPin, 
                    size: 16, 
                    color: city == null ? AppTheme.primaryColor : Colors.grey
                  ),
                  const SizedBox(width: 4),
                  Text(
                    city ?? "Toca para activar ubicación", 
                    style: GoogleFonts.inter(
                      color: city == null ? AppTheme.primaryColor : Colors.grey, 
                      fontSize: 14, 
                      fontWeight: city == null ? FontWeight.bold : FontWeight.w500
                    )
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 12), // Espacio entre ubicación y rol

          // ETIQUETA DE ROL
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
}