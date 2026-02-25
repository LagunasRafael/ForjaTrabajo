import 'dart:io'; // 👈 Importante para usar File
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class Step3Summary extends StatelessWidget {
  final String title;
  final String desc;
  final String address;
  final String price;
  final String? categoryId;
  final AsyncValue<List<dynamic>> categoriesAsync;
  final bool isLoading;
  
  // 👇 NUEVOS PARÁMETROS AGREGADOS
  final List<File> images;
  final VoidCallback onAddImage;
  final Function(int) onRemoveImage;
  
  final VoidCallback onSubmit;
  final VoidCallback onEdit;

  const Step3Summary({
    super.key, 
    required this.title, 
    required this.desc, 
    required this.address, 
    required this.price, 
    required this.categoryId, 
    required this.categoriesAsync, 
    required this.isLoading, 
    required this.images,      // 👈
    required this.onAddImage,   // 👈
    required this.onRemoveImage, // 👈
    required this.onSubmit, 
    required this.onEdit
  });

  @override
  Widget build(BuildContext context) {
    String categoryName = "Seleccionada";
    categoriesAsync.whenData((cats) {
      if (categoryId != null) {
        final cat = cats.firstWhere((c) => c.id == categoryId, orElse: () => null);
        if (cat != null) categoryName = cat.name;
      }
    });

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- SECCIÓN DE FOTOS ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween, 
            children: [
              const Text("Evidencia visual", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)), 
              Text("${images.length} fotos", style: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.bold))
            ]
          ),
          const SizedBox(height: 16),
          
          SizedBox(
            height: 90,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: images.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  // Botón de Añadir Foto
                  return _buildAddPhotoButton();
                }
                // Miniaturas de las fotos ya elegidas
                return _buildImageThumbnail(index - 1);
              },
            ),
          ),

          const SizedBox(height: 40),

          // --- RESUMEN DE DATOS ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween, 
            children: [
              const Text("Resumen de tu solicitud", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)), 
              GestureDetector(onTap: onEdit, child: const Text("Editar", style: TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.bold)))
            ]
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSummaryRow(Icons.work, "SERVICIO", title),
                const Divider(height: 24, color: Color(0xFFF3F4F6)),
                _buildSummaryRow(Icons.category, "CATEGORÍA", categoryName),
                const Divider(height: 24, color: Color(0xFFF3F4F6)),
                _buildSummaryRow(Icons.location_on, "UBICACIÓN", address),
                const Divider(height: 24, color: Color(0xFFF3F4F6)),
                _buildSummaryRow(Icons.attach_money, "PRESUPUESTO", "\$$price MXN", valueColor: const Color(0xFF10B981)),
              ],
            ),
          ),
          
          const SizedBox(height: 40),
          
          // --- BOTÓN FINAL ---
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isLoading ? null : onSubmit,
              icon: isLoading ? const SizedBox() : const Icon(Icons.check_circle_outline, color: Colors.white),
              label: isLoading 
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                : const Text("Publicar Servicio", style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.w900)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5), 
                padding: const EdgeInsets.symmetric(vertical: 18), 
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
              ),
            ),
          )
        ],
      ),
    );
  }

  // --- WIDGETS INTERNOS ---

  Widget _buildAddPhotoButton() {
    return GestureDetector(
      onTap: onAddImage,
      child: Container(
        width: 80,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFEEF2FF), 
          borderRadius: BorderRadius.circular(16), 
          border: Border.all(color: const Color(0xFF4F46E5).withOpacity(0.5), style: BorderStyle.solid)
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center, 
          children: [
            Icon(Icons.add_a_photo, color: Color(0xFF4F46E5)), 
            Text("Añadir", style: TextStyle(color: Color(0xFF4F46E5), fontSize: 12, fontWeight: FontWeight.bold))
          ]
        ),
      ),
    );
  }

  Widget _buildImageThumbnail(int index) {
    return Stack(
      children: [
        Container(
          width: 80,
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            image: DecorationImage(image: FileImage(images[index]), fit: BoxFit.cover),
          ),
        ),
        Positioned(
          right: 16,
          top: 4,
          child: GestureDetector(
            onTap: () => onRemoveImage(index),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
              child: const Icon(Icons.close, size: 14, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(IconData icon, String label, String value, {Color? valueColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey[400]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, 
            children: [
              Text(label, style: TextStyle(color: Colors.grey[400], fontSize: 10, fontWeight: FontWeight.w900)), 
              Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: valueColor ?? const Color(0xFF1F2937)))
            ]
          )
        ),
      ],
    );
  }
}