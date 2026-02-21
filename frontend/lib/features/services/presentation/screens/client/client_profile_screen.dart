import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forja_trabajo/core/theme/app_theme.dart';
import 'package:forja_trabajo/features/auth/presentation/providers/auth_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:forja_trabajo/features/auth/presentation/widgets/profile_shared_widgets.dart';

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
            _buildHeader(user?.fullName ?? "Cliente", user?.email ?? "", "Cliente", user?.profilePictureUrl, user?.city, ref),
            const SizedBox(height: 30),
            
            // 👇 ¡MIRA QUÉ LIMPIO QUEDA! 👇
            ProfileMenuCard(
              children: [
                ProfileMenuOption(icon: LucideIcons.user, title: 'Mi Información', onTap: () {}),
                ProfileMenuOption(icon: LucideIcons.shoppingBag, title: 'Mis Solicitudes de Servicio', onTap: () {}),
                ProfileMenuOption(icon: LucideIcons.creditCard, title: 'Métodos de Pago', onTap: () {}),
                ProfileMenuOption(icon: LucideIcons.bell, title: 'Notificaciones', onTap: () {}),
              ],
            ),
            const SizedBox(height: 32),
            const ProfileLogoutButton(), // 👈 Un solo widget que hace todo
          ],
        ),
      ),
    );
  }

  // (Aquí dejas solo _buildHeader porque es exclusivo del cliente)
}

  // --- WIDGETS REUTILIZABLES ---
  Widget _buildHeader(String name, String email, String role, String? imageUrl,String? city, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.only(top: 60, bottom: 30),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Column(
        children: [
          EditableProfileAvatar(
            imageUrl: imageUrl, // 👈 Le pasamos la URL que recibimos
            radius: 50,
          ),
          const SizedBox(height: 16),
          Text(name, style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold)),
          Text(email, style: GoogleFonts.inter(color: Colors.grey)),
          const SizedBox(height: 12),
          // 👇 LA NUEVA UBICACIÓN INTERACTIVA 👇
          InkWell(
            onTap: () async {
              await ref.read(authProvider.notifier).autoUpdateLocation();
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min, // Para que el toque sea solo en el texto
                children: [
                  Icon(
                    LucideIcons.mapPin, 
                    size: 16, 
                    // Si no hay ciudad, lo pintamos del color principal para que llame la atención
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
          // 👆 FIN DE LA UBICACIÓN INTERACTIVA 👆
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
