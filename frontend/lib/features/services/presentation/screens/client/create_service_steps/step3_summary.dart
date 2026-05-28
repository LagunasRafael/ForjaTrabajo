import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:forja_trabajo/features/services/presentation/widgets/client/step3_widgets.dart';

class Step3Summary extends StatelessWidget {
  final String title;
  final String desc;
  final String address;
  final String price;
  final String? categoryId;
  final AsyncValue<List<dynamic>> categoriesAsync;
  final bool isLoading;
  
  final List<File> images;
  final List<String> existingImageUrls;
  final VoidCallback onAddImage;
  final Function(int) onRemoveImage;
  final Function(int) onRemoveExistingImage;
  
  final VoidCallback onSubmit;
  final VoidCallback onEdit;
  final bool isEditing;

  const Step3Summary({
    super.key, 
    required this.title, 
    required this.desc, 
    required this.address, 
    required this.price, 
    required this.categoryId, 
    required this.categoriesAsync, 
    required this.isLoading, 
    required this.images,      
    required this.existingImageUrls,
    required this.onAddImage,   
    required this.onRemoveImage, 
    required this.onRemoveExistingImage,
    required this.onSubmit, 
    required this.onEdit,
    this.isEditing = false,
  });

  @override
  Widget build(BuildContext context) {
    // Extraemos el nombre de la categoría
    String categoryName = "Seleccionada";
    categoriesAsync.whenData((cats) {
      if (categoryId != null) {
        final cat = cats.firstWhere((c) => c.id == categoryId, orElse: () => null);
        if (cat != null) categoryName = cat.name;
      }
    });

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- SECCIÓN DE FOTOS ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween, 
            children: [
              const Text("Evidencia visual", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)), 
              Text("${existingImageUrls.length + images.length} fotos", style: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.bold))
            ]
          ),
          const SizedBox(height: 16),
          
          SizedBox(
            height: 90,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: existingImageUrls.length + images.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return AddPhotoButton(onTap: onAddImage); 
                }
                final adjusted = index - 1;
                if (adjusted < existingImageUrls.length) {
                  return NetworkImageThumbnail(
                    imageUrl: existingImageUrls[adjusted], 
                    onRemove: () => onRemoveExistingImage(adjusted)
                  );
                }
                final localIndex = adjusted - existingImageUrls.length;
                return ImageThumbnail(
                  imageFile: images[localIndex], 
                  onRemove: () => onRemoveImage(localIndex)
                );
              },
            ),
          ),

          const SizedBox(height: 40),

          // --- RESUMEN DE DATOS ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween, 
            children: [
              const Text("Resumen de tu solicitud", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)), 
              GestureDetector(
                onTap: onEdit, 
                child: const Text("Editar", style: TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.bold))
              )
            ]
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SummaryRow(icon: Icons.work, label: "SERVICIO", value: title),
                const Divider(height: 24, color: Color(0xFFF3F4F6)),
                SummaryRow(icon: Icons.category, label: "CATEGORÍA", value: categoryName),
                const Divider(height: 24, color: Color(0xFFF3F4F6)),
                SummaryRow(icon: Icons.location_on, label: "UBICACIÓN", value: address),
                const Divider(height: 24, color: Color(0xFFF3F4F6)),
                SummaryRow(
                  icon: Icons.attach_money, 
                  label: "PRESUPUESTO", 
                  value: "\$$price MXN", 
                  valueColor: const Color(0xFF10B981)
                ),
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
                : Text(isEditing ? "Guardar Cambios" : "Publicar Servicio", style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.w900)),
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
}