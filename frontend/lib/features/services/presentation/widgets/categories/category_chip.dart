import 'package:flutter/material.dart';

class CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData? icon; // ✅ 1. Agregamos el ícono como opcional

  const CategoryChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.icon, // ✅ 2. Lo declaramos aquí
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4F46E5) : Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected ? Colors.transparent : Colors.grey.shade300,
          ),
        ),
        // ✅ 3. Envolvemos el texto en un Row para que quepa el ícono al lado
        child: Row(
          mainAxisSize: MainAxisSize.min, // Para que el botón no ocupe toda la pantalla
          children: [
            // Si le pasamos un ícono, lo dibuja junto con un pequeño espacio
            if (icon != null) ...[
              Icon(
                icon, 
                size: 18, 
                color: isSelected ? Colors.white : Colors.grey[600]
              ),
              const SizedBox(width: 6),
            ],
            // Tu texto original intacto
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}