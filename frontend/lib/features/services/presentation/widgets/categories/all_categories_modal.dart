import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Asegúrate de que esta ruta apunte bien a tu category_provider.dart
import 'package:forja_trabajo/features/services/presentation/providers/category_provider.dart';

class AllCategoriesModal extends ConsumerWidget {
  final List<dynamic> categories;
  final void Function(String)? onSelected;
  
  const AllCategoriesModal({super.key, required this.categories, this.onSelected});

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
                final isSelected = selectedCatId == cat.id?.toString();
                
                return ListTile(
                  leading: Icon(Icons.category, color: isSelected ? const Color(0xFF4F46E5) : Colors.grey),
                  title: Text(cat.name ?? "S/N", style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                  onTap: () {
                    final String idStr = cat.id?.toString() ?? "";
                    if (onSelected != null) {
                      onSelected!(idStr);
                    } else {
                      ref.read(selectedCategoryProvider.notifier).state = idStr;
                    }
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

void showCategoryModal(BuildContext context, List<dynamic> categories, {void Function(String)? onSelected}) {
  showDialog(
    context: context,
    builder: (_) => AllCategoriesModal(categories: categories, onSelected: onSelected),
  );
}