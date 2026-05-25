import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:forja_trabajo/features/services/presentation/widgets/client/create_service_widgets.dart';
import 'package:forja_trabajo/features/services/presentation/widgets/categories/category_grid_selector.dart';

class Step1Details extends StatefulWidget {
  final TextEditingController titleCtrl, descCtrl;
  final String? selectedCategoryId;
  final Function(String) onCategoryChanged;
  final VoidCallback onNext;
  final AsyncValue<List<dynamic>> categoriesAsync;

  const Step1Details({
    super.key, required this.titleCtrl, required this.descCtrl,
    required this.selectedCategoryId, required this.onCategoryChanged,
    required this.onNext, required this.categoriesAsync,
  });

  @override
  State<Step1Details> createState() => _Step1DetailsState();
}

class _Step1DetailsState extends State<Step1Details> {
  final ScrollController _scrollCtrl = ScrollController();
  final GlobalKey _titleKey    = GlobalKey();
  final GlobalKey _categoryKey = GlobalKey();
  final GlobalKey _descKey     = GlobalKey();
  bool _showCategoryError = false;

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollTo(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      alignment: 0.0,
    );
  }

  void _handleNext() {
    final titleEmpty = widget.titleCtrl.text.trim().isEmpty;
    final catEmpty   = widget.selectedCategoryId == null;
    final descEmpty  = widget.descCtrl.text.trim().isEmpty;

    // Mostrar errores de categoría
    setState(() => _showCategoryError = catEmpty);

    // Disparar bordes rojos en todos los TextFormFields del Form padre
    Form.maybeOf(context)?.validate();

    if (titleEmpty) {
      _scrollTo(_titleKey);
      return;
    }
    if (catEmpty) {
      _scrollTo(_categoryKey);
      return;
    }
    if (descEmpty) {
      _scrollTo(_descKey);
      return;
    }

    setState(() => _showCategoryError = false);
    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: _scrollCtrl,
      padding: const EdgeInsets.all(24),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Título ───────────────────────────────────────────
          SizedBox(key: _titleKey),
          const ServiceSectionLabel("¿Qué necesitas hacer?"),
          ServiceTextField(
            controller: widget.titleCtrl,
            hint: "Ej. Reparación de fuga en lavabo",
            icon: Icons.work_outline,
            validator: (v) => (v == null || v.trim().isEmpty) ? 'El título es obligatorio' : null,
          ),

          const SizedBox(height: 32),

          // ─── Categoría ────────────────────────────────────────
          SizedBox(key: _categoryKey),
          const ServiceSectionLabel("Categoría del servicio"),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: _showCategoryError
                ? BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFEF4444), width: 2),
                  )
                : const BoxDecoration(),
            child: RepaintBoundary(
              child: _CategorySection(
                categoriesAsync: widget.categoriesAsync,
                selectedCategoryId: widget.selectedCategoryId,
                onCategoryChanged: (id) {
                  setState(() => _showCategoryError = false);
                  widget.onCategoryChanged(id);
                },
              ),
            ),
          ),
          if (_showCategoryError)
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 12),
              child: Text(
                'Selecciona una categoría',
                style: TextStyle(color: Colors.red.shade700, fontSize: 12),
              ),
            ),

          const SizedBox(height: 32),

          // ─── Descripción ──────────────────────────────────────
          SizedBox(key: _descKey),
          const ServiceSectionLabel("Detalles del problema"),
          ServiceTextField(
            controller: widget.descCtrl,
            hint: "Describe qué pasó, materiales...",
            maxLines: 5,
            validator: (v) => (v == null || v.trim().isEmpty) ? 'La descripción es obligatoria' : null,
          ),

          const SizedBox(height: 40),
          StepActionButton(text: "Continuar", onPressed: _handleNext),
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
        onSelected: onCategoryChanged,
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