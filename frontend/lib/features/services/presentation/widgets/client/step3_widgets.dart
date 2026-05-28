import 'dart:io';
import 'package:flutter/material.dart';

class AddPhotoButton extends StatelessWidget {
  final VoidCallback onTap;
  const AddPhotoButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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
}

class ImageThumbnail extends StatelessWidget {
  final File imageFile;
  final VoidCallback onRemove;

  const ImageThumbnail({super.key, required this.imageFile, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: 80,
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            image: DecorationImage(image: FileImage(imageFile), fit: BoxFit.cover),
          ),
        ),
        Positioned(
          right: 16,
          top: 4,
          child: GestureDetector(
            onTap: onRemove,
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
}

class NetworkImageThumbnail extends StatelessWidget {
  final String imageUrl;
  final VoidCallback onRemove;

  const NetworkImageThumbnail({super.key, required this.imageUrl, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: 80,
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            image: DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover),
          ),
        ),
        Positioned(
          right: 16,
          top: 4,
          child: GestureDetector(
            onTap: onRemove,
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
}

class SummaryRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const SummaryRow({
    super.key, 
    required this.icon, 
    required this.label, 
    required this.value, 
    this.valueColor
  });

  @override
  Widget build(BuildContext context) {
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