import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/category_provider.dart';
import '../providers/service_list_provider.dart';
import '../widgets/service_card.dart';
import '../screens/create_services_screen.dart';

class HomeServicesScreen extends ConsumerWidget {
  const HomeServicesScreen({super.key});

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
                  _buildHeader(),
                  const SizedBox(height: 20),
                  _buildSearchBar(),
                  const SizedBox(height: 20),

                  // CATEGORÍAS DINÁMICAS DESDE LA DB
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
                          _buildCategoryChip(
                            label: "Ver todas",
                            isSelected: false,
                            icon: Icons.grid_view_rounded,
                            onTap: () => _showAllCategoriesMenu(context, categories, ref),
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
        floatingActionButton: FloatingActionButton(
          backgroundColor: const Color(0xFF4F46E5),
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          onPressed: () {
            // ESTO ES LO QUE FALTABA: LA NAVEGACIÓN
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CreateServiceScreen()),
            );
          },
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        ),
    );
  }

  void _showAllCategoriesMenu(BuildContext context, List<dynamic> categories, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollController) => Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 20), decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
              const Text("Selecciona una categoría", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: categories.length,
                  itemBuilder: (context, i) => ListTile(
                    title: Text(categories[i].name),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      ref.read(selectedCategoryProvider.notifier).state = categories[i].id;
                      Navigator.pop(context);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

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

  Widget _buildHeader() => Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
    const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("Bienvenido de nuevo", style: TextStyle(color: Colors.grey, fontSize: 14)), Text("Hola, Carlos", style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800))]),
    CircleAvatar(
        radius: 24, // O el tamaño que tengas
        backgroundColor: Colors.indigo.shade100, // Fondo suave
        child: const Icon(Icons.person, color: Colors.indigo), // Icono seguro
      ),
  ]);

  Widget _buildSearchBar() => Container(padding: const EdgeInsets.symmetric(horizontal: 15), decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(16)), child: const TextField(decoration: InputDecoration(hintText: "Buscar servicios...", prefixIcon: Icon(Icons.search), border: InputBorder.none)));
}