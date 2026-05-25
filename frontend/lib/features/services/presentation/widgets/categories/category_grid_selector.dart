import 'package:flutter/material.dart';

import 'package:forja_trabajo/features/services/presentation/screens/shared/utils/category_icon_helper.dart';
import 'package:forja_trabajo/features/services/presentation/widgets/categories/all_categories_modal.dart';

class CategoryGridSelector extends StatelessWidget {
  final List<dynamic> categories;
  final String? selectedId;
  final void Function(String) onSelected;

  const CategoryGridSelector({
    super.key, 
    required this.categories, 
    required this.selectedId, 
    required this.onSelected
  });

  @override
  Widget build(BuildContext context) {
    // 1. Siempre mostramos las primeras 5 categorías fijas
    List<dynamic> displayCats = categories.take(5).toList();
    
    // 2. Buscamos si la seleccionada está fuera de esas 5
    dynamic externalSelectedCat;
    bool isSelectedInGrid = displayCats.any((c) => c.id?.toString() == selectedId);
    
    if (selectedId != null && !isSelectedInGrid) {
      // Usamos where para evitar el error de "orElse: () => null" con tipos estrictos
      final matched = categories.where((c) => c.id?.toString() == selectedId).toList();
      if (matched.isNotEmpty) {
        externalSelectedCat = matched.first;
      }
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - 24) / 3;

        return Wrap(
          spacing: 12, 
          runSpacing: 12,
          children: [
            ...displayCats.map((cat) => _CategoryCard(
              cat: cat, 
              isSelected: selectedId == cat.id?.toString(), 
              onTap: () => onSelected(cat.id?.toString() ?? ""),
              width: cardWidth,
            )),
            
            // El botón de "Ver más" ahora se vuelve "dinámico"
            _SeeMoreCard(
              selectedCat: externalSelectedCat,
              onTap: () => showCategoryModal(
                context, 
                categories, 
                onSelected: (id) => onSelected(id) // Envoltura explícita para evitar líos de tipos
              ),
              width: cardWidth,
            ),
          ],
        );
      }
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final dynamic cat;
  final bool isSelected;
  final VoidCallback onTap;
  final double width;

  const _CategoryCard({
    required this.cat, 
    required this.isSelected, 
    required this.onTap,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    final String catName = cat.name.toString();
    final iconColor = isSelected ? const Color(0xFF4F46E5) : Colors.grey[400];

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: width,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEEF2FF) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF4F46E5) : Colors.grey.shade200, 
            width: isSelected ? 2 : 1
          ),
        ),
        child: Column(
          children: [
            Icon(catName.toCategoryIcon, color: iconColor, size: 32),
            const SizedBox(height: 12),
            Text(
              catName, 
              textAlign: TextAlign.center, 
              maxLines: 1, 
              overflow: TextOverflow.ellipsis, 
              style: TextStyle(
                color: isSelected ? const Color(0xFF4F46E5) : Colors.grey[700], 
                fontSize: 11, 
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
              )
            ),
          ],
        ),
      ),
    );
  }
}

class _SeeMoreCard extends StatelessWidget {
  final dynamic selectedCat;
  final VoidCallback onTap;
  final double width;

  const _SeeMoreCard({
    this.selectedCat,
    required this.onTap,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    final bool isSelected = selectedCat != null;
    final String catName = isSelected ? selectedCat.name.toString() : "Ver más";
    final icon = isSelected ? catName.toCategoryIcon : Icons.grid_view_rounded;
    final primaryColor = isSelected ? const Color(0xFF4F46E5) : Colors.grey;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: width,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEEF2FF) : const Color(0xFFF9FAFB), 
          borderRadius: BorderRadius.circular(20), 
          border: Border.all(
            color: isSelected ? const Color(0xFF4F46E5) : Colors.grey.shade300,
            width: isSelected ? 2 : 1
          )
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? primaryColor : Colors.grey, size: 32),
            const SizedBox(height: 12),
            Text(
              catName, 
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isSelected ? primaryColor : Colors.grey, 
                fontSize: 11, 
                fontWeight: FontWeight.bold
              )
            ),
          ],
        ),
      ),
    );
  }
}