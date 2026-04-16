import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:forja_trabajo/features/services/presentation/widgets/client/create_service_widgets.dart'; 
import 'package:forja_trabajo/features/services/presentation/widgets/categories/category_grid_selector.dart';

class Step1Details extends StatelessWidget {
  final TextEditingController titleCtrl, descCtrl;
  final String? selectedCategoryId;
  final Function(String) onCategoryChanged;
  final VoidCallback onNext;
  final AsyncValue<List<dynamic>> categoriesAsync;

  const Step1Details({
    super.key, required this.titleCtrl, required this.descCtrl, 
    required this.selectedCategoryId, required this.onCategoryChanged, 
    required this.onNext, required this.categoriesAsync
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ServiceSectionLabel("¿Qué necesitas hacer?"),
          ServiceTextField(
            controller: titleCtrl, 
            hint: "Ej. Reparación de fuga en lavabo", 
            icon: Icons.work_outline
          ),
          
          const SizedBox(height: 32),
          const ServiceSectionLabel("Categoría del servicio"),
          
          RepaintBoundary(
            child: _CategorySection(
              categoriesAsync: categoriesAsync,
              selectedCategoryId: selectedCategoryId,
              onCategoryChanged: onCategoryChanged,
            ),
          ),
          
          const SizedBox(height: 32),
          const ServiceSectionLabel("Detalles del problema"),
          ServiceTextField(
            controller: descCtrl, 
            hint: "Describe qué pasó, materiales...", 
            maxLines: 5
          ),
          
          const SizedBox(height: 40),
          StepActionButton(text: "Continuar", onPressed: onNext),
        ],
      ),
    );
  }
}

class _CategorySection extends StatelessWidget {
  final AsyncValue<List<dynamic>> categoriesAsync;
  final String? selectedCategoryId;
  final Function(String) onCategoryChanged;

  const _CategorySection({
    required this.categoriesAsync,
    required this.selectedCategoryId,
    required this.onCategoryChanged,
  });

  @override
  Widget build(BuildContext context) {
    return categoriesAsync.when(
      data: (categories) => CategoryGridSelector(
        categories: categories, 
        selectedId: selectedCategoryId, 
        onSelected: onCategoryChanged
      ),
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 32),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (_, __) => const Text("Error al cargar categorías"),
    );
  }
}