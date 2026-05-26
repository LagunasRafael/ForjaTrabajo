import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:forja_trabajo/core/theme/app_theme.dart';
import 'package:forja_trabajo/features/auth/presentation/providers/auth_provider.dart';
import 'package:forja_trabajo/features/services/presentation/providers/category_provider.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _bioController;
  final Set<String> _selectedCategoryIds = {};
  String _categorySearchQuery = '';
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // 1. Leemos el usuario actual directo del estado de Riverpod al abrir la pantalla
    final user = ref.read(authProvider).user;

    // 2. Pre-llenamos los campos con su info
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

  void _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final newName = _nameController.text.trim();
      final newPhone = _phoneController.text.trim();
      final bio = _bioController.text.trim();

      try {
        final user = ref.read(authProvider).user;
        
        // Llamamos al provider con los parámetros nombrados requeridos
        await ref.read(authProvider.notifier).updateUserInfo(
              newName: newName,
              newPhone: newPhone,
              bio: user != null && user.isWorker ? bio : null,
              categoryIds: user != null && user.isWorker
                  ? _selectedCategoryIds.toList()
                  : null,
            );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Perfil actualizado exitosamente')),
          );
          Navigator.pop(context);
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
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final isWorker = user?.isWorker ?? false;
    final categoryListAsync = ref.watch(categoryListProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        iconTheme: theme.iconTheme,
        centerTitle: true,
        title: Text(
          "Editar Perfil",
          style: GoogleFonts.inter(
            color: theme.textTheme.titleLarge?.color ?? AppTheme.textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Nombre Completo",
                style: GoogleFonts.inter(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: "Ej. Rafael Lagunas",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.person_outline),
                ),
                validator: (value) =>
                    value!.trim().isEmpty ? "El nombre es obligatorio" : null,
              ),
              const SizedBox(height: 24),
              Text(
                "Teléfono",
                style: GoogleFonts.inter(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                decoration: InputDecoration(
                  hintText: "Ej. 5512345678 (10 dígitos)",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.phone_outlined),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'El teléfono es obligatorio';
                  if (v.length != 10) return 'El teléfono debe tener 10 dígitos';
                  return null;
                },
              ),
              if (isWorker) ...[
                const SizedBox(height: 24),
                // Biografía
                Text(
                  'Biografía / Descripción Profesional',
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextFormField(
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
                const SizedBox(height: 24),
                // Mis Categorías
                Text(
                  'Mis Categorías de Servicio (Máx. 5)',
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                // Buscador de categorías
                TextField(
                  onChanged: (val) {
                    setState(() {
                      _categorySearchQuery = val.trim().toLowerCase();
                    });
                  },
                  decoration: InputDecoration(
                    hintText: "Buscar categorías...",
                    prefixIcon: const Icon(Icons.search, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
                const SizedBox(height: 12),
                categoryListAsync.when(
                  data: (categories) {
                    final filteredCategories = categories.where((cat) {
                      final nameMatch = cat.name.toLowerCase().contains(_categorySearchQuery);
                      final descMatch = cat.description.toLowerCase().contains(_categorySearchQuery);
                      return nameMatch || descMatch;
                    }).toList();

                    if (filteredCategories.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(24.0),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          "No se encontraron categorías",
                          style: GoogleFonts.inter(color: Colors.grey, fontSize: 14),
                        ),
                      );
                    }

                    return Container(
                      constraints: const BoxConstraints(maxHeight: 180),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: filteredCategories.length,
                        itemBuilder: (context, index) {
                          final cat = filteredCategories[index];
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
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (err, _) => Text(
                    'Error al cargar categorías: $err',
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ],
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark
                        ? const Color(0xFF4F46E5)
                        : const Color(0xFF1E1B4B), // Adaptado para modo oscuro
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "Guardar Cambios",
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
