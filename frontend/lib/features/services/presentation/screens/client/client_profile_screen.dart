import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forja_trabajo/core/theme/app_theme.dart';
import 'package:forja_trabajo/features/auth/presentation/providers/auth_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:forja_trabajo/features/auth/presentation/widgets/profile_shared_widgets.dart';
import 'package:forja_trabajo/features/services/presentation/screens/client/edit_profile_screen.dart';
import 'package:forja_trabajo/features/profile/presentation/settings_screen.dart';
import 'package:forja_trabajo/features/profile/presentation/screens/user_profile_screen.dart';
import 'package:forja_trabajo/features/services/presentation/providers/nav_providers.dart';
import 'package:forja_trabajo/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:forja_trabajo/features/profile/presentation/screens/identity_verification_screen.dart';
import 'package:forja_trabajo/features/profile/presentation/providers/public_profile_provider.dart';

class ClientProfileScreen extends ConsumerWidget {
  const ClientProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final verificationAsync = ref.watch(verificationStatusProvider);

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(
              user?.fullName ?? "Cliente",
              user?.email ?? "",
              "Cliente",
              user?.profilePictureUrl,
              user?.city,
              user?.isIdentityVerified ?? false,
              ref,
              isDark,
            ),
            const SizedBox(height: 30),

            ProfileMenuCard(
              [
                ProfileMenuOption(
                    icon: LucideIcons.user,
                    title: 'Mi Información',
                    onTap: () {
                      if (user != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                UserProfileScreen(userId: user.id),
                          ),
                        );
                      }
                    }),
                ProfileMenuOption(
                    icon: LucideIcons.shoppingBag,
                    title: 'Mis Solicitudes de Servicio',
                    onTap: () {
                      ref.read(clientNavProvider.notifier).state = 3;
                    }),
                ProfileMenuOption(
                    icon: LucideIcons.creditCard,
                    title: 'Métodos de Pago',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Métodos de pago en desarrollo'),
                        ),
                      );
                    }),
                ProfileMenuOption(
                    icon: LucideIcons.fileText,
                    title: 'Mis Facturas',
                    onTap: () {
                      Navigator.pushNamed(context, '/client/invoices');
                    }),
                ProfileMenuOption(
                    icon: LucideIcons.bell,
                    title: 'Notificaciones',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NotificationsScreen(),
                        ),
                      );
                    }),
                if (user?.isIdentityVerified != true &&
                    verificationAsync.valueOrNull?['has_pending_verification'] != true)
                  ProfileMenuOption(
                      icon: LucideIcons.shieldCheck,
                      title: 'Verificar Identidad',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const IdentityVerificationScreen(),
                          ),
                        ).then((_) {
                          ref.invalidate(verificationStatusProvider);
                          ref.invalidate(authProvider);
                        });
                      }),
                ProfileMenuOption(
                  icon: LucideIcons.pencil,
                  title: 'Editar Perfil',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const EditProfileScreen()),
                    );
                  },
                ),
                ProfileMenuOption(
                  icon: LucideIcons.settings,
                  title: 'Configuración',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const SettingsScreen()),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 32),
            const ProfileLogoutButton(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String name, String email, String role, String? imageUrl,
      String? city, bool isIdentityVerified, WidgetRef ref, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 60, bottom: 30),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          EditableProfileAvatar(
            imageUrl: imageUrl,
            radius: 50,
          ),
          const SizedBox(height: 16),
          Text(name,
              style:
                  GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold)),
          if (isIdentityVerified)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.verified, color: Colors.blue, size: 18),
                  const SizedBox(width: 4),
                  Text('Identidad Verificada',
                      style: GoogleFonts.inter(color: Colors.blue, fontSize: 13, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
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
                  Icon(LucideIcons.mapPin,
                      size: 16,
                      color:
                          city == null ? AppTheme.primaryColor : Colors.grey),
                  const SizedBox(width: 4),
                  Text(city ?? "Toca para activar ubicación",
                      style: GoogleFonts.inter(
                          color: city == null
                              ? AppTheme.primaryColor
                              : Colors.grey,
                          fontSize: 14,
                          fontWeight: city == null
                              ? FontWeight.bold
                              : FontWeight.w500)),
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
            child: Text(role.toUpperCase(),
                style: const TextStyle(
                    color: AppTheme.primaryColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
