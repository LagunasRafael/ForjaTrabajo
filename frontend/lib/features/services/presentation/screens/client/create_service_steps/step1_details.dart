import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class Step1Details extends StatelessWidget {
  final TextEditingController titleCtrl;
  final TextEditingController descCtrl;
  final String? selectedCategoryId;
  final Function(String) onCategoryChanged;
  final VoidCallback onNext;
  final AsyncValue<List<dynamic>> categoriesAsync;

  const Step1Details({
    super.key,
    required this.titleCtrl,
    required this.descCtrl,
    required this.selectedCategoryId,
    required this.onCategoryChanged,
    required this.onNext,
    required this.categoriesAsync,
  });

  IconData _getCategoryIcon(String categoryName) {
    final name = categoryName.toLowerCase();
    if (name.contains('plom') || name.contains('fuga')) return Icons.plumbing;
    if (name.contains('electr') || name.contains('luz')) return Icons.electric_bolt;
    if (name.contains('carp') || name.contains('mueb')) return Icons.handyman;
    if (name.contains('pint')) return Icons.format_paint;
    if (name.contains('limp')) return Icons.cleaning_services;
    if (name.contains('mec') || name.contains('auto')) return Icons.car_repair;
    return Icons.category;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("¿Qué necesitas hacer?", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          _buildTextField(titleCtrl, "Ej. Reparación de fuga en lavabo", icon: Icons.work_outline),
          
          const SizedBox(height: 32),
          const Text("Categoría del servicio", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          
          categoriesAsync.when(
            data: (categories) {
              List<dynamic> displayCats = categories.take(5).toList();

              if (selectedCategoryId != null && !displayCats.any((c) => c.id == selectedCategoryId)) {
                final hiddenSelectedCat = categories.firstWhere((c) => c.id == selectedCategoryId, orElse: () => null);
                if (hiddenSelectedCat != null) {
                  displayCats = List.from(displayCats); 
                  displayCats[4] = hiddenSelectedCat; 
                }
              }

              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  ...displayCats.map((cat) => _buildCategoryCard(context, cat)).toList(),
                  _buildSeeAllCard(context, categories),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const Text("Error al cargar categorías"),
          ),
          
          const SizedBox(height: 32),
          const Text("Detalles del problema", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          _buildTextField(descCtrl, "Describe qué pasó, medidas, qué materiales tienes o necesitas...", maxLines: 5),
          
          const SizedBox(height: 40),
          _buildNextButton("Continuar", onNext),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(BuildContext context, dynamic cat) {
    final isSelected = selectedCategoryId == cat.id;
    return GestureDetector(
      onTap: () => onCategoryChanged(cat.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: (MediaQuery.of(context).size.width - 72) / 3, 
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEEF2FF) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? const Color(0xFF4F46E5) : Colors.grey.shade200, width: isSelected ? 2 : 1),
        ),
        child: Column(
          children: [
            Icon(_getCategoryIcon(cat.name), color: isSelected ? const Color(0xFF4F46E5) : Colors.grey[400], size: 32),
            const SizedBox(height: 12),
            Text(cat.name, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: isSelected ? const Color(0xFF4F46E5) : Colors.grey[700], fontSize: 12, fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildSeeAllCard(BuildContext context, List<dynamic> allCategories) {
    return GestureDetector(
      onTap: () => _showAllCategoriesModal(context, allCategories),
      child: Container(
        width: (MediaQuery.of(context).size.width - 72) / 3, 
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade300, width: 1),
        ),
        child: Column(
          children: [
            Icon(Icons.grid_view_rounded, color: Colors.grey[500], size: 32),
            const SizedBox(height: 12),
            const Text("Ver más", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  // 👇 AQUÍ ESTÁ EL CAMBIO PRINCIPAL: UN DIÁLOGO FLOTANTE (FANTASMA) EN EL CENTRO
  void _showAllCategoriesModal(BuildContext context, List<dynamic> allCategories) {
    showDialog(
      context: context,
      barrierDismissible: true, // Permite cerrar tocando fuera
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent, // Fondo transparente para el efecto flotante
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40), // Separación de las orillas
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7, // Altura máxima del 70% de la pantalla
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                )
              ]
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min, // Se adapta a la cantidad de elementos, pero sin pasarse del maxHeight
              children: [
                // Cabecera del pop-up
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 16, 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Todas las categorías", 
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF111827))
                      ),
                      IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(color: Colors.grey[100], shape: BoxShape.circle),
                          child: Icon(Icons.close, color: Colors.grey[600], size: 20)
                        ),
                        onPressed: () => Navigator.pop(context),
                      )
                    ],
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFF3F4F6)),
                // Lista de categorías
                Flexible(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    shrinkWrap: true,
                    itemCount: allCategories.length,
                    itemBuilder: (context, i) {
                      final cat = allCategories[i];
                      final isSelected = selectedCategoryId == cat.id;
                      
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: isSelected ? const Color(0xFFEEF2FF) : Colors.grey[100], borderRadius: BorderRadius.circular(12)),
                            child: Icon(_getCategoryIcon(cat.name), color: isSelected ? const Color(0xFF4F46E5) : Colors.grey[600]),
                          ),
                          title: Text(cat.name, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.w600, color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFF374151))),
                          trailing: isSelected ? const Icon(Icons.check_circle, color: Color(0xFF4F46E5)) : null,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          tileColor: isSelected ? const Color(0xFFF5F8FF) : Colors.transparent,
                          onTap: () {
                            onCategoryChanged(cat.id);
                            Navigator.pop(context); // Cierra el pop-up automáticamente
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String hint, {int maxLines = 1, IconData? icon}) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      style: const TextStyle(fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400]),
        prefixIcon: icon != null ? Icon(icon, color: Colors.grey[400]) : null,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 2)),
      ),
    );
  }

  Widget _buildNextButton(String text, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF111827), padding: const EdgeInsets.symmetric(vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text(text, style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)), const SizedBox(width: 8), const Icon(Icons.arrow_forward_rounded, color: Colors.white)]),
      ),
    );
  }
}