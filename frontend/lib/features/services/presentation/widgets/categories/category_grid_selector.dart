import 'package:flutter/material.dart';

import 'package:forja_trabajo/features/services/presentation/screens/shared/utils/category_icon_helper.dart';
import 'package:forja_trabajo/features/services/presentation/widgets/categories/all_categories_modal.dart';

class CategoryGridSelector extends StatelessWidget {
  final List<dynamic> categories;
  final String? selectedId;
  final Function(String) onSelected;

  const CategoryGridSelector({
    super.key, 
    required this.categories, 
    required this.selectedId, 
    required this.onSelected
  });

  @override
  Widget build(BuildContext context) {
    List<dynamic> displayCats = categories.take(5).toList();
    
    if (selectedId != null && !displayCats.any((c) => c.id == selectedId)) {
      final selected = categories.firstWhere((c) => c.id == selectedId, orElse: () => null);
      if (selected != null) displayCats[4] = selected;
    }

    // 🛡️ SOLUCIÓN AL LAG: Usamos LayoutBuilder en lugar de MediaQuery
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculamos el ancho exacto que le toca a cada tarjeta (3 columnas con 12px de espacio)
        // El 24 representa los dos espacios de 12px entre las 3 columnas
        final cardWidth = (constraints.maxWidth - 24) / 3;

        return Wrap(
          spacing: 12, 
          runSpacing: 12,
          children: [
            ...displayCats.map((cat) => _CategoryCard(
              cat: cat, 
              isSelected: selectedId == cat.id, 
              onTap: () => onSelected(cat.id),
              width: cardWidth, // Le pasamos el ancho fijo
            )),
            
            _SeeMoreCard(
              onTap: () => showCategoryModal(context, categories),
              width: cardWidth, // Le pasamos el ancho fijo
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
  final double width; // 🚀 Recibimos el ancho como parámetro constante

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
        width: width, // 🚀 Usamos el ancho estático
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
  final VoidCallback onTap;
  final double width; // 🚀 Recibimos el ancho como parámetro constante

  const _SeeMoreCard({
    required this.onTap,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width, // 🚀 Usamos el ancho estático
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB), 
          borderRadius: BorderRadius.circular(20), 
          border: Border.all(color: Colors.grey.shade300)
        ),
        child: const Column(
          children: [
            Icon(Icons.grid_view_rounded, color: Colors.grey, size: 32),
            const SizedBox(height: 12),
            Text(
              "Ver más", 
              style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)
            ),
          ],
        ),
      ),
    );
  }
}