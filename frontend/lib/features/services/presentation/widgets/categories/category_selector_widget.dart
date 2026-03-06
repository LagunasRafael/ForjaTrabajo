import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forja_trabajo/features/services/presentation/providers/category_provider.dart';
import 'package:forja_trabajo/features/services/presentation/widgets/categories/category_chip.dart';
import 'package:forja_trabajo/features/services/presentation/widgets/categories/all_categories_modal.dart';

class CategorySelectorWidget extends ConsumerWidget {
  const CategorySelectorWidget({super.key});

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
                onTap: () => showCategoryModal(context, allCats), 
              ),
              orElse: () => const SizedBox(),
            ),
          ],
        ),
      ),
      loading: () => const LinearProgressIndicator(color: Color(0xFF4F46E5)),
      error: (e, s) => const Text("Error al cargar categorías", style: TextStyle(color: Colors.red)),
    );
  }
}