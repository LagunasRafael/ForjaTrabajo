import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forja_trabajo/features/services/presentation/providers/category_provider.dart';
import 'package:forja_trabajo/features/services/presentation/providers/service_list_provider.dart';
import 'package:forja_trabajo/features/auth/presentation/providers/auth_provider.dart';
import 'package:forja_trabajo/shared/widgets/service_card_skeleton.dart'; 
import '../../widgets/service_card.dart';

// ✅ IMPORTANTE: Verifica que esta ruta apunte a tu archivo global CategoryChip
import '../../widgets/category_chip.dart'; 

class MarketplaceScreen extends StatelessWidget {
  const MarketplaceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              color: Colors.white,
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _WorkerHeader(),
                  SizedBox(height: 20),
                  _SearchBar(),
                  SizedBox(height: 20),
                  _CategoryListSection(),
                ],
              ),
            ),
            const Expanded(
              child: Column(
                children: [
                  Expanded(child: _ServiceList()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkerHeader extends ConsumerWidget {
  const _WorkerHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final userName = authState.user?.fullName ?? 'Trabajador';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween, 
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, 
            children: [
              const Text("Bienvenido", style: TextStyle(color: Colors.grey, fontSize: 14)), 
              Text("Hola, $userName", style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, overflow: TextOverflow.ellipsis), maxLines: 1),
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
  }
}

class _SearchBar extends ConsumerWidget {
  const _SearchBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(16)),
      child: TextField(
        onChanged: (value) => ref.read(searchQueryProvider.notifier).state = value,
        decoration: const InputDecoration(
          hintText: "Buscar por título...", 
          prefixIcon: Icon(Icons.search), 
          border: InputBorder.none
        ),
      ),
    );
  }
}

class _CategoryListSection extends ConsumerWidget {
  const _CategoryListSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topCategoriesAsync = ref.watch(topCategoryListProvider);
    final allCategoriesAsync = ref.watch(categoryListProvider);
    final selectedCatId = ref.watch(selectedCategoryProvider);

    return topCategoriesAsync.when(
      data: (categories) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            // ✅ USANDO TU WIDGET GLOBAL AQUÍ
            CategoryChip(
              label: "Todos",
              isSelected: selectedCatId == null,
              onTap: () => ref.read(selectedCategoryProvider.notifier).state = null,
            ),
            ...categories.map((cat) => CategoryChip(
              label: cat.name,
              isSelected: selectedCatId == cat.id,
              onTap: () => ref.read(selectedCategoryProvider.notifier).state = cat.id,
            )),
            
            allCategoriesAsync.maybeWhen(
              data: (list) => CategoryChip(
                label: "Ver más...",
                isSelected: false,
                onTap: () => _showAllCategoriesModal(context, list, ref, selectedCatId),
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
}

class _ServiceList extends ConsumerWidget {
  const _ServiceList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final servicesAsync = ref.watch(serviceListProvider);

    return servicesAsync.when(
      data: (services) => services.isEmpty 
        ? const Center(child: Text("No hay trabajos disponibles"))
        : ListView.builder(
            padding: const EdgeInsets.only(bottom: 80),
            itemCount: services.length,
            itemBuilder: (context, index) => ServiceCard(service: services[index]),
          ),
      loading: () => ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        itemBuilder: (context, index) => const ServiceCardSkeleton(),
      ),
      error: (e, s) => Center(child: Text("Error: $e")),
    );
  }
}

// --- FUNCIONES AUXILIARES ---

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