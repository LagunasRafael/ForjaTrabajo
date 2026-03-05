import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Providers
import 'package:forja_trabajo/features/services/presentation/providers/category_provider.dart';
import 'package:forja_trabajo/features/services/presentation/providers/service_list_provider.dart';
import 'package:forja_trabajo/features/auth/presentation/providers/auth_provider.dart';

// Widgets y Temas
import '../../widgets/service_card.dart';

class HomeClientScreen extends ConsumerWidget {
  const HomeClientScreen({super.key});

  // Lógica de íconos unificada
  IconData _getCategoryIcon(String categoryName) {
    final name = categoryName.toLowerCase();
    if (name.contains('plom')) return Icons.plumbing;
    if (name.contains('electr')) return Icons.electric_bolt;
    if (name.contains('carp')) return Icons.handyman;
    if (name.contains('pint')) return Icons.format_paint;
    if (name.contains('limp')) return Icons.cleaning_services;
    if (name.contains('mec')) return Icons.car_repair;
    return Icons.category;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. ESCUCHAMOS LOS PROVIDERS
    final servicesAsync = ref.watch(serviceListProvider);
    final allCategoriesAsync = ref.watch(categoryListProvider);
    final topCategoriesAsync = ref.watch(topCategoryListProvider);

    final selectedCatId = ref.watch(selectedCategoryProvider);
    final authState = ref.watch(authProvider);

    // Datos del usuario desde el servidor
    final userName = authState.user?.fullName ?? 'Usuario';
    final userImageUrl = authState.user?.profilePictureUrl;

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // --- CABECERA ---
            Container(
              padding: const EdgeInsets.all(20),
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(userName, userImageUrl),
                  const SizedBox(height: 20),
                  _buildSearchBar(ref, isDark),
                  const SizedBox(height: 20),

                  // --- CARRUSEL DE CATEGORÍAS ---
                  topCategoriesAsync.when(
                    data: (topCategories) => SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: [
                          _buildCategoryChip(
                            label: "Todos",
                            isSelected: selectedCatId == null,
                            onTap: () => ref
                                .read(selectedCategoryProvider.notifier)
                                .state = null,
                            isDark: isDark,
                          ),
                          ...topCategories.map((cat) => _buildCategoryChip(
                                label: cat.name,
                                isSelected: selectedCatId == cat.id,
                                onTap: () => ref
                                    .read(selectedCategoryProvider.notifier)
                                    .state = cat.id,
                                isDark: isDark,
                              )),
                          allCategoriesAsync.maybeWhen(
                            data: (allCats) => _buildCategoryChip(
                              label: "Ver más",
                              isSelected: false,
                              icon: Icons.grid_view_rounded,
                              onTap: () => _showAllCategoriesModal(
                                  context, allCats, ref, selectedCatId),
                            ),
                            orElse: () => const SizedBox(),
                          ),
                        ],
                      ),
                    ),
                    loading: () => const LinearProgressIndicator(),
                    error: (e, s) => const Text("Error al cargar categorías"),
                  ),
                ],
              ),
            ),

            // --- LISTA DE EMPLEOS ---
            Expanded(
              child: Column(
                children: [
                  _buildSectionTitle(ref),
                  Expanded(
                    child: servicesAsync.when(
                      data: (services) => services.isEmpty
                          ? const Center(
                              child: Text("No hay servicios disponibles"))
                          : ListView.builder(
                              padding: const EdgeInsets.only(bottom: 80),
                              itemCount: services.length,
                              itemBuilder: (context, index) =>
                                  ServiceCard(service: services[index]),
                            ),
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (e, s) => Center(child: Text("Error: $e")),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGETS DE APOYO ---

  Widget _buildHeader(String name, String? imageUrl) =>
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text("Bienvenido de nuevo",
                style: TextStyle(color: Colors.grey, fontSize: 14)),
            Text("Hola, $name",
                style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    overflow: TextOverflow.ellipsis),
                maxLines: 1)
          ]),
        ),
        const SizedBox(width: 12),
        // Foto de perfil circular con imagen de red o icono por defecto
        CircleAvatar(
          radius: 26,
          backgroundColor: Colors.indigo.shade50,
          backgroundImage: (imageUrl != null && imageUrl.isNotEmpty)
              ? NetworkImage(imageUrl)
              : null,
          child: (imageUrl == null || imageUrl.isEmpty)
              ? const Icon(Icons.person, color: Colors.indigo, size: 28)
              : null,
        ),
      ]);

  Widget _buildSectionTitle(WidgetRef ref) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Empleos Disponibles",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            TextButton(
              onPressed: () {
                ref.read(selectedCategoryProvider.notifier).state = null;
                ref.read(searchQueryProvider.notifier).state = "";
              },
              child: const Text("Ver todos",
                  style: TextStyle(color: Color(0xFF2563EB), fontSize: 13)),
            ),
          ],
        ),
      );

  Widget _buildSearchBar(WidgetRef ref, bool isDark) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        decoration: BoxDecoration(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(16)),
        child: TextField(
          onChanged: (value) =>
              ref.read(searchQueryProvider.notifier).state = value,
          decoration: const InputDecoration(
              hintText: "Buscar trabajos...",
              prefixIcon: Icon(Icons.search, color: Colors.grey),
              border: InputBorder.none),
        ),
      );

  Widget _buildCategoryChip(
      {required String label,
      required bool isSelected,
      required VoidCallback onTap,
      IconData? icon,
      bool isDark = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF4F46E5)
              : (isDark ? const Color(0xFF1E293B) : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: isSelected
                  ? Colors.transparent
                  : (isDark ? Colors.grey.shade700 : Colors.grey.shade300)),
        ),
        child: Row(
          children: [
            if (icon != null)
              Icon(icon,
                  size: 16,
                  color: isSelected ? Colors.white : Colors.grey[600]),
            if (icon != null) const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey[700],
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  void _showAllCategoriesModal(BuildContext context,
      List<dynamic> allCategories, WidgetRef ref, String? selectedCatId) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Todas las categorías",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context)),
                ],
              ),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: allCategories.length,
                itemBuilder: (context, i) {
                  final cat = allCategories[i];
                  final isSelected = selectedCatId == cat.id;
                  return ListTile(
                    leading: Icon(_getCategoryIcon(cat.name),
                        color:
                            isSelected ? const Color(0xFF4F46E5) : Colors.grey),
                    title: Text(cat.name,
                        style: TextStyle(
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal)),
                    onTap: () {
                      ref.read(selectedCategoryProvider.notifier).state =
                          cat.id;
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
