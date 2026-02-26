import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forja_trabajo/core/theme/app_theme.dart';
import 'package:forja_trabajo/features/auth/presentation/providers/auth_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

// 👇 IMPORTS NECESARIOS PARA LIMPIAR LA MEMORIA
import 'package:forja_trabajo/features/services/presentation/providers/service_list_provider.dart';
// Si tienes un provider para el índice del menú (ej. bottomNavIndexProvider), impórtalo aquí.

// 1. EL MENÚ BLANCO CON SOMBRA (Sin cambios)
class ProfileMenuCard extends StatelessWidget {
  final List<Widget> children;
  
  const ProfileMenuCard({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03), 
            blurRadius: 20
          )
        ],
      ),
      child: Column(children: children),
    );
  }
}

// 2. CADA OPCIÓN DEL MENÚ (Sin cambios)
class ProfileMenuOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const ProfileMenuOption({
    super.key, 
    required this.icon, 
    required this.title, 
    required this.onTap
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryColor, size: 20),
      title: Text(title, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w500)),
      trailing: const Icon(LucideIcons.chevronRight, size: 20),
      onTap: onTap,
    );
  }
}

// 3. EL BOTÓN ROJO DE CERRAR SESIÓN (MODIFICADO 🚀)
// 3. EL BOTÓN ROJO DE CERRAR SESIÓN (CORREGIDO)
class ProfileLogoutButton extends ConsumerWidget {
  const ProfileLogoutButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: OutlinedButton.icon(
        onPressed: () async {
          // 1. Borramos token y datos de sesión
          await ref.read(authProvider.notifier).logoutUser();
          
          // 2. 🧹 LIMPIEZA PROFUNDA DE MEMORIA (Invalidamos todo lo que tenga datos viejos)
          // Esto soluciona el error "No se pudo validar la sesión"
          ref.invalidate(myRequestsProvider); 
          ref.invalidate(serviceListProvider); 
          ref.invalidate(authProvider); // Invalidamos también la auth para asegurar

          // 3. 🔄 RESETEAR EL MENÚ AL INICIO (Soluciona que inicie en la página incorrecta)
          // IMPORTANTE: Cambia 'bottomNavIndexProvider' por el nombre real de tu provider del menú
          try {
             // Si usas StateProvider:
             // ref.read(bottomNavIndexProvider.notifier).state = 0; 
             
             // O simplemente invalídalo para que vuelva a su valor original (0):
             // ref.invalidate(bottomNavIndexProvider);
          } catch (e) {
             print("Ojo: No encontré el provider del menú, revisa el nombre");
          }

          // 4. Navegación radical: Borra todo el historial y manda al Login
          if (context.mounted) {
            Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
          }
        },
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 56),
          side: const BorderSide(color: AppTheme.dangerRose),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        icon: const Icon(LucideIcons.logOut, color: AppTheme.dangerRose),
        label: Text("Cerrar Sesión", style: GoogleFonts.inter(color: AppTheme.dangerRose, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

// 4. AVATAR EDITABLE (Sin cambios)
class EditableProfileAvatar extends ConsumerWidget {
  final String? imageUrl;
  final double radius;

  const EditableProfileAvatar({
    super.key, 
    this.imageUrl, 
    this.radius = 50,
  });

  Future<void> _pickImage(BuildContext context, WidgetRef ref, ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, imageQuality: 80); 
    
    if (pickedFile != null) {
      await ref.read(authProvider.notifier).updateProfilePicture(pickedFile);
    }
  }

  void _showOptionsBottomSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Wrap(
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Text(
                    'Foto de perfil',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(LucideIcons.camera, color: AppTheme.primaryColor),
                  ),
                  title: Text('Tomar foto', style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
                  onTap: () {
                    Navigator.pop(context); 
                    _pickImage(context, ref, ImageSource.camera); 
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(LucideIcons.image, color: AppTheme.primaryColor),
                  ),
                  title: Text('Elegir de la galería', style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
                  onTap: () {
                    Navigator.pop(context); 
                    _pickImage(context, ref, ImageSource.gallery); 
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => _showOptionsBottomSheet(context, ref),
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          CircleAvatar(
            radius: radius,
            backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
            backgroundImage: imageUrl != null ? NetworkImage(imageUrl!) : null,
            child: imageUrl == null 
                ? Icon(LucideIcons.user, size: radius, color: AppTheme.primaryColor)
                : null,
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: const Icon(LucideIcons.camera, size: 16, color: Colors.white),
          ),
        ],
      ),
    );
  }
}