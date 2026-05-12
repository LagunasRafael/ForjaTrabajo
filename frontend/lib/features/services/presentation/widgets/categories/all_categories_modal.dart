import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Asegúrate de que esta ruta apunte bien a tu category_provider.dart
import 'package:forja_trabajo/features/services/presentation/providers/category_provider.dart';

class AllCategoriesModal extends ConsumerWidget {
  final List<dynamic> categories;
  
  const AllCategoriesModal({super.key, required this.categories});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCatId = ref.watch(selectedCategoryProvider);

    return Dialog(
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
              itemCount: categories.length,
              itemBuilder: (context, i) {
                final cat = categories[i];
                final isSelected = selectedCatId == cat.id;
                
                return ListTile(
                  // Un ícono genérico para que no pida helpers extraños
                  leading: Icon(Icons.category, color: isSelected ? const Color(0xFF4F46E5) : Colors.grey),
                  title: Text(cat.name, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                  onTap: () {
                    // Actualiza el estado y cierra el modal
                    ref.read(selectedCategoryProvider.notifier).state = cat.id;
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Función cortita para llamarlo desde tu category_selector_widget
void showCategoryModal(BuildContext context, List<dynamic> categories) {
  showDialog(
    context: context,
    builder: (_) => AllCategoriesModal(categories: categories),
  );
}