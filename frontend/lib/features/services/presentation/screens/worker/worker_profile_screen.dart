import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forja_trabajo/core/theme/app_theme.dart';
import 'package:forja_trabajo/features/auth/presentation/providers/auth_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

// 👇 AQUÍ IMPORTAMOS TUS COMPONENTES COMPARTIDOS
import 'package:forja_trabajo/features/auth/presentation/widgets/profile_shared_widgets.dart';

class WorkerProfileScreen extends ConsumerWidget {
  const WorkerProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 24),
            
            // 👇 1. EL AVATAR TOCABLE CON CÁMARA (Estilo WhatsApp)
            EditableProfileAvatar(
              imageUrl: user?.profilePictureUrl,
              radius: 60,
            ),
            
            const SizedBox(height: 16),
            Text(user?.fullName ?? "Cargando...", style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold)),
            
            // 👇 2. EL BADGE DE ROL SIMPLIFICADO
            Container(
              margin: const EdgeInsets.only(top: 8, bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.successEmerald.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text("TRABAJADOR", 
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.successEmerald)),
            ),

            // 👇 3. LA UBICACIÓN ARREGLADA (user?.city)
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
                      color: user?.city == null ? AppTheme.primaryColor : Colors.grey
                    ),
                    const SizedBox(width: 4),
                    Text(
                      user?.city ?? "Toca para activar ubicación", 
                      style: GoogleFonts.inter(
                        color: user?.city == null ? AppTheme.primaryColor : Colors.grey, 
                        fontSize: 14, 
                        fontWeight: user?.city == null ? FontWeight.bold : FontWeight.w500
                      )
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // 👇 4. EL MENÚ LIMPIO (Usando Shared Widgets)
            ProfileMenuCard(
              children: [
                ProfileMenuOption(icon: LucideIcons.briefcase, title: 'Mi Portafolio', onTap: () {}),
                ProfileMenuOption(icon: LucideIcons.star, title: 'Mis Reseñas', onTap: () {}),
                ProfileMenuOption(icon: LucideIcons.history, title: 'Historial de Trabajos', onTap: () {}),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // 👇 5. EL BOTÓN DE LOGOUT (Usando Shared Widgets)
            const ProfileLogoutButton(),
            
            const SizedBox(height: 24), // Espacio al final
          ],
        ),
      ),
    );
  }
}