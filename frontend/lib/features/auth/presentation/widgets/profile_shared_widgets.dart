import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forja_trabajo/core/theme/app_theme.dart';
import 'package:forja_trabajo/features/auth/presentation/providers/auth_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:forja_trabajo/features/auth/presentation/screens/login_screen.dart';
import 'package:forja_trabajo/features/profile/presentation/settings_screen.dart';

// 1. EL MENÚ BLANCO CON SOMBRA
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

// 2. CADA OPCIÓN DEL MENÚ
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

// 3. EL BOTÓN ROJO DE CERRAR SESIÓN (CORREGIDO)
class ProfileLogoutButton extends ConsumerWidget {
  const ProfileLogoutButton({super.key});

  // Movimos la función de confirmación aquí adentro
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
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text("Cancelar", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                // Asegúrate de que el método sea logout o logoutUser según tu provider
                ref.read(authProvider.notifier).logoutUser(); 
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: OutlinedButton.icon(
        onPressed: () => _showLogoutConfirmation(context, ref), // Ahora sí se llama al presionar
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

// 4. EL AVATAR EDITABLE (CORREGIDO)
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
      // Asegúrate de que tu provider tenga este método implementado
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
                  child: Text('Foto de perfil', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                ListTile(
                  leading: _buildIconContainer(LucideIcons.camera),
                  title: Text('Tomar foto', style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(context, ref, ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: _buildIconContainer(LucideIcons.image),
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

  Widget _buildIconContainer(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: AppTheme.primaryColor),
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
            backgroundImage: imageUrl != null && imageUrl!.isNotEmpty 
                ? NetworkImage(imageUrl!) 
                : null,
            child: (imageUrl == null || imageUrl!.isEmpty)
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