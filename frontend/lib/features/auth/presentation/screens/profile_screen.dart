import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';
import '../../../services/presentation/providers/category_provider.dart';
import '../../../services/domain/entities/category_entity.dart';
import '../../../services/data/models/category_model.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Escuchamos el estado completo de Autenticación
    final authState = ref.watch(authProvider);
    final user = authState.user;

    final theme = Theme.of(context);

    // 2. Extraemos los datos dinámicos (con valores por defecto si aún está cargando)
    final String userName = user?.fullName ?? "Cargando...";
    final String userEmail = user?.email ?? "Cargando...";
    final String userRole = user?.role ?? "...";
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Mi Perfil',
          style: GoogleFonts.inter(
            color: theme.textTheme.titleLarge?.color ?? AppTheme.textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 24),
            // --- FOTO DE PERFIL Y DATOS BÁSICOS ---
            Center(
              child: Stack(
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      border: Border.all(
                          color: AppTheme.primaryColor.withOpacity(0.2),
                          width: 4),
                    ),
                    child: const Center(
                      child: Icon(LucideIcons.user,
                          size: 60, color: AppTheme.primaryColor),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: AppTheme.primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(LucideIcons.pencil,
                          color: Colors.white, size: 16),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              userName,
              style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color:
                      theme.textTheme.titleLarge?.color ?? AppTheme.textColor),
            ),
            const SizedBox(height: 4),
            // 📍 NUEVO: LA UBICACIÓN MÁGICA
            if (user?.city != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(LucideIcons.mapPin,
                      size: 14, color: AppTheme.primaryColor),
                  const SizedBox(width: 4),
                  Text(
                    user!.city!, // Aquí dirá ej. "Ciudad Hidalgo, Michoacán"
                    style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.primaryColor),
                  ),
                ],
              ),
              const SizedBox(height: 4),
            ],
            Text(
              userEmail,
              style: GoogleFonts.inter(
                  fontSize: 14, color: AppTheme.subtitleColor),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.successEmerald.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                userRole.toUpperCase(),
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.successEmerald,
                ),
              ),
            ),
            const SizedBox(height: 40),

            // --- OPCIONES DEL PERFIL ---
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 20,
                      offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                children: [
                  _buildProfileOption(
                    icon: LucideIcons.userCog,
                    title: 'Editar Datos Personales',
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => const _EditProfileModal(),
                      );
                    },
                    theme: theme,
                  ),
                  _buildDivider(theme),
                  _buildProfileOption(
                    icon: LucideIcons.lock,
                    title: 'Cambiar Contraseña',
                    onTap: () {},
                    theme: theme,
                  ),
                  _buildDivider(theme),
                  _buildProfileOption(
                    icon: LucideIcons.creditCard,
                    title: 'Métodos de Pago',
                    onTap: () {},
                    theme: theme,
                  ),
                  _buildDivider(theme),
                  _buildProfileOption(
                    icon: LucideIcons.helpCircle,
                    title: 'Soporte y Ayuda',
                    onTap: () {},
                    theme: theme,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // --- BOTÓN DE CERRAR SESIÓN ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton.icon(
                  onPressed: () {
                    // LÓGICA DE CIERRE DE SESIÓN
                    ref.read(authProvider.notifier).logoutUser();
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const LoginScreen()),
                      (route) => false,
                    );
                  },
                  icon: const Icon(LucideIcons.logOut,
                      color: AppTheme.dangerRose),
                  label: Text(
                    'Cerrar Sesión',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.dangerRose,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(
                        color: AppTheme.dangerRose, width: 1.5),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // Widgets de ayuda para mantener el código limpio
  Widget _buildProfileOption(
      {required IconData icon,
      required String title,
      required VoidCallback onTap,
      required ThemeData theme}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            shape: BoxShape.circle),
        child: Icon(icon, color: AppTheme.primaryColor, size: 20),
      ),
      title: Text(title,
          style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              color: theme.textTheme.bodyLarge?.color ?? AppTheme.textColor,
              fontSize: 15)),
      trailing:
          const Icon(LucideIcons.chevronRight, color: Colors.grey, size: 20),
      onTap: onTap,
    );
  }

  Widget _buildDivider(ThemeData theme) {
    return Divider(
        height: 1,
        thickness: 1,
        color: theme.brightness == Brightness.dark
            ? const Color(0xFF334155)
            : Colors.grey.shade100,
        indent: 70,
        endIndent: 24);
  }
}

class _EditProfileModal extends ConsumerStatefulWidget {
  const _EditProfileModal({super.key});

  @override
  ConsumerState<_EditProfileModal> createState() => _EditProfileModalState();
}

class _EditProfileModalState extends ConsumerState<_EditProfileModal> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _bioController;
  final Set<String> _selectedCategoryIds = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    _nameController = TextEditingController(text: user?.fullName ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
    _bioController = TextEditingController(text: user?.bio ?? '');
    if (user?.categories != null) {
      _selectedCategoryIds.addAll(user!.categories!.map((c) => c.id));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    setState(() {
      _isLoading = true;
    });

    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final bio = _bioController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El nombre no puede estar vacío')),
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final user = ref.read(authProvider).user;
      await ref.read(authProvider.notifier).updateUserInfo(
            newName: name,
            newPhone: phone,
            bio: user != null && user.isWorker ? bio : null,
            categoryIds: user != null && user.isWorker
                ? _selectedCategoryIds.toList()
                : null,
          );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil actualizado exitosamente')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al actualizar el perfil: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final isWorker = user?.isWorker ?? false;
    final categoryListAsync = ref.watch(categoryListProvider);
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 48,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Editar Datos Personales',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: theme.textTheme.titleLarge?.color ?? AppTheme.textColor,
              ),
            ),
            const SizedBox(height: 24),
            // Nombre Completo
            Text(
              'Nombre Completo',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: theme.textTheme.bodyMedium?.color ?? AppTheme.textColor,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'Tu nombre completo',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              maxLength: 100,
              buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
            ),
            const SizedBox(height: 16),
            // Teléfono
            Text(
              'Número de Teléfono',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: theme.textTheme.bodyMedium?.color ?? AppTheme.textColor,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                hintText: 'Ej. 4431234567',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              maxLength: 15,
              buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
            ),
            if (isWorker) ...[
              const SizedBox(height: 16),
              // Biografía
              Text(
                'Biografía / Descripción Profesional',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: theme.textTheme.bodyMedium?.color ?? AppTheme.textColor,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _bioController,
                maxLines: 4,
                maxLength: 400,
                decoration: InputDecoration(
                  hintText: 'Cuéntales a tus clientes sobre tu experiencia y habilidades...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 16),
              // Mis Categorías
              Text(
                'Mis Categorías de Servicio (Máx. 5)',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: theme.textTheme.bodyMedium?.color ?? AppTheme.textColor,
                ),
              ),
              const SizedBox(height: 8),
              categoryListAsync.when(
                data: (categories) {
                  return Container(
                    constraints: const BoxConstraints(maxHeight: 180),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        final cat = categories[index];
                        final isSelected = _selectedCategoryIds.contains(cat.id);
                        return CheckboxListTile(
                          title: Text(cat.name, style: GoogleFonts.inter(fontSize: 14)),
                          value: isSelected,
                          activeColor: AppTheme.primaryColor,
                          controlAffinity: ListTileControlAffinity.leading,
                          onChanged: (bool? checked) {
                            setState(() {
                              if (checked == true) {
                                if (_selectedCategoryIds.length >= 5) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Solo puedes seleccionar hasta 5 categorías')),
                                  );
                                  return;
                                }
                                _selectedCategoryIds.add(cat.id);
                              } else {
                                _selectedCategoryIds.remove(cat.id);
                              }
                            });
                          },
                        );
                      },
                    ),
                  );
                },
                loading: () => const Center(child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                )),
                error: (err, _) => Text('Error al cargar categorías: $err', style: const TextStyle(color: Colors.red)),
              ),
            ],
            const SizedBox(height: 32),
            // Botón de Guardar
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        'Guardar Cambios',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
