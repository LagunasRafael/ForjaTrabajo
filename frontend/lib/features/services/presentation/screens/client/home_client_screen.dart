import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forja_trabajo/features/services/presentation/providers/category_provider.dart';
import 'package:forja_trabajo/features/services/presentation/providers/service_list_provider.dart';
import 'package:forja_trabajo/features/auth/presentation/providers/auth_provider.dart'; 
import '../../widgets/service_card.dart';
import 'package:forja_trabajo/shared/widgets/service_card_skeleton.dart'; 
import '../../widgets/category_chip.dart'; 

class HomeClientScreen extends StatelessWidget {
  const HomeClientScreen({super.key});

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
                  _ClientHeader(),
                  SizedBox(height: 20),
                  _SearchBar(),
                  SizedBox(height: 20),
                  _CategoryListSection(),
                ],
              ),
            ),

            // --- LISTA DE EMPLEOS ---
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

class _ClientHeader extends ConsumerWidget {
  const _ClientHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final userName = authState.user?.fullName ?? 'Usuario';
    final userImageUrl = authState.user?.profilePictureUrl;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween, 
      children: [
        Expanded( 
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, 
            children: [
              const Text("Bienvenido de nuevo", style: TextStyle(color: Colors.grey, fontSize: 14)), 
              Text(
                "Hola, $userName", 
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, overflow: TextOverflow.ellipsis), 
                maxLines: 1
              )
            ]
          ),
        ),
        const SizedBox(width: 12),
        CircleAvatar(
          radius: 26,
          backgroundColor: Colors.indigo.shade50,
          backgroundImage: (userImageUrl != null && userImageUrl.isNotEmpty) 
              ? NetworkImage(userImageUrl) 
              : null,
          child: (userImageUrl == null || userImageUrl.isEmpty)
              ? const Icon(Icons.person, color: Colors.indigo, size: 28)
              : null,
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
          hintText: "Buscar trabajos...", 
          prefixIcon: Icon(Icons.search, color: Colors.grey), 
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
      data: (topCategories) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            CategoryChip(
              label: "Todos",
              isSelected: selectedCatId == null,
              onTap: () => ref.read(selectedCategoryProvider.notifier).state = null,
            ),
            ...topCategories.map((cat) => CategoryChip(
              label: cat.name,
              isSelected: selectedCatId == cat.id,
              onTap: () => ref.read(selectedCategoryProvider.notifier).state = cat.id,
            )),
            allCategoriesAsync.maybeWhen(
              data: (allCats) => CategoryChip(
                label: "Ver más",
                isSelected: false,
                icon: Icons.grid_view_rounded, 
                onTap: () => _showAllCategoriesModal(context, allCats, ref, selectedCatId),
              ),
              orElse: () => const SizedBox(),
            ),
          ],
        ),
      ),
      loading: () => const LinearProgressIndicator(),
      error: (e, s) => const Text("Error al cargar categorías"),
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
        ? const Center(child: Text("No hay servicios disponibles"))
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