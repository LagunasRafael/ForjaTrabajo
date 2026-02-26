import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forja_trabajo/features/services/presentation/providers/category_provider.dart';
import 'package:forja_trabajo/features/services/presentation/providers/service_list_provider.dart';
import 'package:forja_trabajo/features/auth/presentation/providers/auth_provider.dart'; 
import '../../widgets/service_card.dart';
import 'package:forja_trabajo/shared/widgets/service_card_skeleton.dart';

class MarketplaceScreen extends ConsumerWidget {
  const MarketplaceScreen({super.key});

  IconData _getCategoryIcon(String categoryName) {
    final name = categoryName.toLowerCase();
    if (name.contains('plom') || name.contains('fuga')) return Icons.plumbing;
    if (name.contains('electr') || name.contains('luz')) return Icons.electric_bolt;
    if (name.contains('carp') || name.contains('mueb')) return Icons.handyman;
    if (name.contains('pint')) return Icons.format_paint;
    if (name.contains('limp')) return Icons.cleaning_services;
    if (name.contains('mec') || name.contains('auto')) return Icons.car_repair;
    return Icons.category;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final servicesAsync = ref.watch(serviceListProvider);
    final allCategoriesAsync = ref.watch(categoryListProvider);
    final topCategoriesAsync = ref.watch(topCategoryListProvider);
    
    final selectedCatId = ref.watch(selectedCategoryProvider);
    final authState = ref.watch(authProvider);
    final userName = authState.user?.fullName ?? 'Trabajador';

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Column(
          children: [
            // --- CABECERA Y CATEGORÍAS ---
            Container(
              padding: const EdgeInsets.all(20),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildWorkerHeader(userName),
                  const SizedBox(height: 20),
                  _buildSearchBar(ref),
                  const SizedBox(height: 20),
                  _buildCategoryList(ref, topCategoriesAsync, allCategoriesAsync, selectedCatId),
                ],
              ),
            ),

            // --- LISTADO DE TRABAJOS ---
            Expanded(
              child: Column(
                children: [
                  _buildSectionHeader(ref),
                  Expanded(
                    child: servicesAsync.when(
                      data: (services) => services.isEmpty 
                        ? const Center(child: Text("No hay trabajos disponibles"))
                        : ListView.builder(
                            padding: const EdgeInsets.only(bottom: 80),
                            itemCount: services.length,
                            itemBuilder: (context, index) => ServiceCard(service: services[index]),
                          ),
                      // Usamos los esqueletos de develop para una carga elegante
                      loading: () => ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: 5,
                        itemBuilder: (context, index) => const ServiceCardSkeleton(),
                      ),
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

  // --- WIDGETS AUXILIARES ---

  Widget _buildSectionHeader(WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text("Trabajos Disponibles", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          TextButton(
            onPressed: () {
              ref.read(selectedCategoryProvider.notifier).state = null;
              ref.read(searchQueryProvider.notifier).state = "";
            },
            child: const Text("Ver todos", style: TextStyle(color: Color(0xFF2563EB), fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryList(WidgetRef ref, AsyncValue topCats, AsyncValue allCats, String? selectedId) {
    return topCats.when(
      data: (categories) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            _buildCategoryChip(
              label: "Todos",
              isSelected: selectedId == null,
              onTap: () => ref.read(selectedCategoryProvider.notifier).state = null,
            ),
            ...categories.map((cat) => _buildCategoryChip(
              label: cat.name,
              isSelected: selectedId == cat.id,
              onTap: () => ref.read(selectedCategoryProvider.notifier).state = cat.id,
            )),
            allCats.maybeWhen(
              data: (list) => _buildCategoryChip(
                label: "Ver más",
                isSelected: false,
                icon: Icons.grid_view_rounded,
                onTap: () => _showAllCategoriesModal(ref.context, list, ref, selectedId),
              ),
              orElse: () => const SizedBox(),
            ),
          ],
        ),
      ),
      loading: () => const LinearProgressIndicator(),
      error: (e, s) => const SizedBox(),
    );
  }

  Widget _buildWorkerHeader(String name) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween, 
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, 
          children: [
            const Text("Bienvenido", style: TextStyle(color: Colors.grey, fontSize: 14)), 
            Text("Hola, $name", style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, overflow: TextOverflow.ellipsis), maxLines: 1),
            const SizedBox(height: 4),
            const Text("Encuentra tu próxima chamba 🛠️", style: TextStyle(fontSize: 14, color: Color(0xFF4F46E5), fontWeight: FontWeight.w600)),
          ]
        ),
      ),
      CircleAvatar(
        radius: 24,
        backgroundColor: Colors.orange.shade100,
        child: const Icon(Icons.handyman, color: Colors.orange),
      ),
    ]
  );

  Widget _buildSearchBar(WidgetRef ref) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 15),
    decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(16)),
    child: TextField(
      onChanged: (value) => ref.read(searchQueryProvider.notifier).state = value,
      decoration: const InputDecoration(hintText: "Buscar por título...", prefixIcon: Icon(Icons.search), border: InputBorder.none),
    ),
  );

  Widget _buildCategoryChip({required String label, required bool isSelected, required VoidCallback onTap, IconData? icon}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4F46E5) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? Colors.transparent : Colors.grey.shade300),
        ),
        child: Row(
          children: [
            if (icon != null) Icon(icon, size: 16, color: isSelected ? Colors.white : Colors.grey[600]),
            if (icon != null) const SizedBox(width: 6),
            Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.grey[700], fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  void _showAllCategoriesModal(BuildContext context, List<dynamic> allCategories, WidgetRef ref, String? selectedCatId) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Todas las categorías", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: allCategories.length,
                itemBuilder: (context, i) {
                  final cat = allCategories[i];
                  final isSelected = selectedCatId == cat.id;
                  return ListTile(
                    leading: Icon(_getCategoryIcon(cat.name), color: isSelected ? const Color(0xFF4F46E5) : Colors.grey),
                    title: Text(cat.name, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                    onTap: () {
                      ref.read(selectedCategoryProvider.notifier).state = cat.id;
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