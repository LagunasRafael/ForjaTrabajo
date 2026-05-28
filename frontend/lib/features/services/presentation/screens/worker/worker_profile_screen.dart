import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forja_trabajo/core/network/api_client.dart';
import 'package:forja_trabajo/core/theme/app_theme.dart';
import 'package:forja_trabajo/features/auth/presentation/providers/auth_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:forja_trabajo/features/auth/presentation/widgets/profile_shared_widgets.dart';
import 'package:forja_trabajo/features/profile/presentation/settings_screen.dart';
import 'package:forja_trabajo/features/services/presentation/screens/client/edit_profile_screen.dart';
import 'package:forja_trabajo/features/profile/presentation/screens/user_profile_screen.dart';
import 'package:forja_trabajo/features/services/presentation/providers/nav_providers.dart';
import 'package:forja_trabajo/features/profile/presentation/screens/identity_verification_screen.dart';
import 'package:forja_trabajo/features/profile/presentation/providers/public_profile_provider.dart';
import 'package:forja_trabajo/features/payments/presentation/providers/wallet_status_provider.dart';
import 'package:forja_trabajo/features/payments/presentation/screens/wallet_screen.dart';

class WorkerProfileScreen extends ConsumerStatefulWidget {
  const WorkerProfileScreen({super.key});

  @override
  ConsumerState<WorkerProfileScreen> createState() =>
      _WorkerProfileScreenState();
}

class _WorkerProfileScreenState extends ConsumerState<WorkerProfileScreen> with WidgetsBindingObserver {
  bool _isSettingUpWallet = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      ref.invalidate(walletStatusProvider);
    }
  }

  Future<void> _setupWallet() async {
    final user = ref.read(authProvider).user;
    if (user == null) return;

    setState(() => _isSettingUpWallet = true);

    try {
      final response = await ApiClient().dio.post(
        '/workers/stripe-setup',
        data: {'user_id': user.id},
      );

      final url = response.data['url'] as String;

      if (url == '__ALREADY_COMPLETED__') {
        ref.invalidate(walletStatusProvider);
        return;
      }

      if (mounted) {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.platformDefault);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al configurar billetera: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSettingUpWallet = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final verificationAsync = ref.watch(verificationStatusProvider);

    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 24),

            EditableProfileAvatar(
              imageUrl: user?.profilePictureUrl,
              radius: 60,
            ),

            const SizedBox(height: 16),
            Text(user?.fullName ?? "Cargando...",
                style: GoogleFonts.inter(
                    fontSize: 24, fontWeight: FontWeight.bold)),
            if (user?.isIdentityVerified == true)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.verified, color: Colors.blue, size: 18),
                    const SizedBox(width: 4),
                    Text('Identidad Verificada',
                        style: GoogleFonts.inter(
                            color: Colors.blue,
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),

            Container(
              margin: const EdgeInsets.only(top: 8, bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.successEmerald.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text("TRABAJADOR",
                  style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.successEmerald)),
            ),

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
                        color: user?.city == null
                            ? AppTheme.primaryColor
                            : Colors.grey),
                    const SizedBox(width: 4),
                    Text(user?.city ?? "Toca para activar ubicación",
                        style: GoogleFonts.inter(
                            color: user?.city == null
                                ? AppTheme.primaryColor
                                : Colors.grey,
                            fontSize: 14,
                            fontWeight: user?.city == null
                                ? FontWeight.bold
                                : FontWeight.w500)),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            ProfileMenuCard(
              [
                ProfileMenuOption(
                    icon: LucideIcons.user,
                    title: 'Editar Perfil',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const EditProfileScreen()),
                      );
                    }),
                ProfileMenuOption(
                    icon: LucideIcons.briefcase,
                    title: 'Mi Portafolio',
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
                    icon: LucideIcons.star,
                    title: 'Mis Reseñas',
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
                _WalletOption(
                  isSettingUp: _isSettingUpWallet,
                  onSetup: _setupWallet,
                ),
                ProfileMenuOption(
                    icon: LucideIcons.history,
                    title: 'Historial de Trabajos',
                    onTap: () {
                      ref.read(workerJobsTabProvider.notifier).state = 2;
                      ref.read(workerNavProvider.notifier).state = 2;
                    }),
                ProfileMenuOption(
                    icon: LucideIcons.clipboardList,
                    title: 'Mis Solicitudes',
                    onTap: () {
                      ref.read(workerNavProvider.notifier).state = 2;
                    }),
                if (user?.isIdentityVerified != true &&
                    verificationAsync.valueOrNull?[
                            'has_pending_verification'] !=
                        true)
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
                    icon: LucideIcons.settings,
                    title: 'Configuración',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const SettingsScreen()),
                      );
                    }),
              ],
            ),

            const SizedBox(height: 32),

            const ProfileLogoutButton(),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _WalletOption extends ConsumerWidget {
  final bool isSettingUp;
  final VoidCallback onSetup;

  const _WalletOption({
    required this.isSettingUp,
    required this.onSetup,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(walletStatusProvider);

    return statusAsync.when(
      data: (status) {
        if (status.isReady) {
          return ProfileMenuOption(
            icon: LucideIcons.wallet,
            title: 'Mi Billetera',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const WalletScreen(),
                ),
              );
            },
          );
        }
        return ListTile(
          leading: Icon(LucideIcons.wallet,
              color: AppTheme.primaryColor, size: 20),
          title: Text(
            'Configurar mi Billetera',
            style: GoogleFonts.inter(
                fontSize: 15, fontWeight: FontWeight.w500),
          ),
          trailing: isSettingUp
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(LucideIcons.chevronRight, size: 20),
          onTap: isSettingUp ? null : onSetup,
        );
      },
      loading: () => ListTile(
        leading: Icon(LucideIcons.wallet,
            color: AppTheme.primaryColor, size: 20),
        title: Text(
          'Configurar mi Billetera',
          style: GoogleFonts.inter(
              fontSize: 15, fontWeight: FontWeight.w500),
        ),
        trailing: const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: (_, __) => ListTile(
        leading: Icon(LucideIcons.wallet,
            color: AppTheme.primaryColor, size: 20),
        title: Text(
          'Configurar mi Billetera',
          style: GoogleFonts.inter(
              fontSize: 15, fontWeight: FontWeight.w500),
        ),
        trailing: isSettingUp
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(LucideIcons.chevronRight, size: 20),
        onTap: isSettingUp ? null : onSetup,
      ),
    );
  }
}
