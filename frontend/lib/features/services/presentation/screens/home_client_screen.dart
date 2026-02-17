import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/screens/role_selection_screen.dart';

class HomeClientScreen extends ConsumerWidget {
  const HomeClientScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        title: Text(
          'Explorar Servicios',
          style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          // BOTÓN DE CERRAR SESIÓN
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () {
              // 1. Borramos el token usando tu provider
              ref.read(authProvider.notifier).logoutUser();
              
              // 2. Lo mandamos de regreso a la pantalla de inicio
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const RoleSelectionScreen()),
                (route) => false, // Esto destruye el historial para que no pueda darle "Atrás"
              );
            },
          )
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.construction, size: 80, color: AppTheme.primaryColor),
            const SizedBox(height: 16),
            Text(
              '¡Bienvenido al Home del Cliente!',
              style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Aquí mostraremos las chambas pronto...',
              style: GoogleFonts.inter(color: AppTheme.subtitleColor),
            ),
          ],
        ),
      ),
    );
  }
}