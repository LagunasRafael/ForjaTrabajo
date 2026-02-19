import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forja_trabajo/features/services/presentation/providers/category_provider.dart';
import 'package:forja_trabajo/features/services/presentation/providers/service_list_provider.dart';
import '../../widgets/service_card.dart';

// 👇 ESTA ES LA DEL WORKER (Sin el botón flotante)
class MarketplaceScreen extends ConsumerWidget {
  const MarketplaceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final servicesAsync = ref.watch(serviceListProvider);
    final categoriesAsync = ref.watch(categoryListProvider);
    final selectedCatId = ref.watch(selectedCategoryProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 👇 Le cambiamos el texto al Worker
                  _buildWorkerHeader(),
                  const SizedBox(height: 20),
                  _buildSearchBar(),
                  const SizedBox(height: 20),

                  // CATEGORÍAS
                  categoriesAsync.when(
                    data: (categories) => SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildCategoryChip(
                            label: "Todos",
                            isSelected: selectedCatId == null,
                            onTap: () => ref.read(selectedCategoryProvider.notifier).state = null,
                          ),
                          ...categories.map((cat) => _buildCategoryChip(
                            label: cat.name,
                            isSelected: selectedCatId == cat.id,
                            onTap: () => ref.read(selectedCategoryProvider.notifier).state = cat.id,
                          )),
                        ],
                      ),
                    ),
                    loading: () => const LinearProgressIndicator(),
                    error: (e, s) => const Text("Error al cargar categorías"),
                  ),
                ],
              ),
            ),

            Expanded(
              child: servicesAsync.when(
                data: (services) => ListView.builder(
                  padding: const EdgeInsets.only(top: 10, bottom: 80),
                  itemCount: services.length,
                  itemBuilder: (context, index) => ServiceCard(service: services[index]),
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, s) => Center(child: Text("Error: $e")),
              ),
            ),
          ],
        ),
      ),
      // ❌ AQUÍ YA NO HAY BOTÓN FLOTANTE PORQUE ES WORKER
    );
  }

  Widget _buildCategoryChip({required String label, required bool isSelected, required VoidCallback onTap}) {
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
        child: Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.grey[700], fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildWorkerHeader() => Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
    const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text("Marketplace", style: TextStyle(color: Colors.grey, fontSize: 14)), 
      Text("Encuentra Trabajo", style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800))
    ]),
    CircleAvatar(
        radius: 24,
        backgroundColor: Colors.orange.shade100, // Color distinto para Worker
        child: const Icon(Icons.work, color: Colors.orange),
      ),
  ]);

  Widget _buildSearchBar() => Container(padding: const EdgeInsets.symmetric(horizontal: 15), decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(16)), child: const TextField(decoration: InputDecoration(hintText: "Buscar trabajos...", prefixIcon: Icon(Icons.search), border: InputBorder.none)));
}