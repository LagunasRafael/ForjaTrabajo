import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ServiceCardSkeleton extends StatelessWidget {
  const ServiceCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        // 👇 AQUÍ EMPIEZA LA MAGIA DEL SHIMMER
        child: Shimmer.fromColors(
          baseColor: Colors.grey[300]!,      // Gris base
          highlightColor: Colors.grey[100]!, // El brillo que pasa por encima
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // 1. El Avatar falso
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // 2. Las líneas de título falsas
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(width: double.infinity, height: 16, color: Colors.white),
                        const SizedBox(height: 8),
                        Container(width: 100, height: 12, color: Colors.white),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // 3. El chip de estado falso
                  Container(
                    width: 70, 
                    height: 24, 
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12)
                    )
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // 4. Descripción falsa
              Container(width: double.infinity, height: 14, color: Colors.white),
              const SizedBox(height: 8),
              Container(width: 200, height: 14, color: Colors.white),
              
              const SizedBox(height: 24),
              
              // 5. Botones falsos
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 40, 
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10))
                    )
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      height: 40, 
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10))
                    )
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}