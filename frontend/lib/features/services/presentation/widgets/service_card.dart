import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/service_entity.dart';
import '../providers/category_provider.dart';

class ServiceCard extends ConsumerWidget {
  final ServiceEntity service;
  const ServiceCard({super.key, required this.service});

  // Íconos y colores simulando tu imagen
  IconData _getCategoryIcon(String categoryName) {
    final name = categoryName.toLowerCase();
    if (name.contains('font') || name.contains('plom') || name.contains('fuga')) return Icons.plumbing;
    if (name.contains('electr')) return Icons.lightbulb_outline;
    if (name.contains('mueb') || name.contains('carp')) return Icons.chair_alt;
    if (name.contains('pint')) return Icons.format_paint;
    return Icons.home_repair_service;
  }

  Color _getIconBackgroundColor(String title) {
    final t = title.toLowerCase();
    if (t.contains('fuga')) return const Color(0xFFF3F4F6); // Gris clarito
    if (t.contains('eléctr')) return const Color(0xFFFEF3C7); // Amarillito
    if (t.contains('roble') || t.contains('mueb')) return const Color(0xFFF3F4F6); 
    if (t.contains('pint')) return const Color(0xFFECFDF5); // Verdecito
    return const Color(0xFFEEF2FF);
  }

  Color _getIconColor(String title) {
    final t = title.toLowerCase();
    if (t.contains('fuga')) return const Color(0xFF2563EB); // Azul
    if (t.contains('eléctr')) return const Color(0xFFD97706); // Naranja
    if (t.contains('roble') || t.contains('mueb')) return const Color(0xFF2563EB);
    if (t.contains('pint')) return const Color(0xFF10B981); // Verde
    return const Color(0xFF4F46E5);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoryListProvider);
    
    // Para ver si mostramos botón azul fuerte o clarito (como en tu imagen)
    final isUrgent = service.title.toLowerCase().contains('urgente');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- LADO IZQUIERDO: Ícono Cuadrado Grande ---
                  categoriesAsync.when(
                    data: (categories) {
                      final categoryName = categories.where((c) => c.id == service.categoryId).map((c) => c.name).firstWhere((name) => true, orElse: () => "");
                      return Container(
                        width: 65,
                        height: 65,
                        decoration: BoxDecoration(
                          color: _getIconBackgroundColor(service.title),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _getCategoryIcon(categoryName.isEmpty ? service.title : categoryName), 
                          color: _getIconColor(service.title), 
                          size: 32
                        ),
                      );
                    },
                    loading: () => Container(width: 65, height: 65, color: Colors.grey[100]),
                    error: (_, __) => Container(width: 65, height: 65, color: Colors.grey[100]),
                  ),

                  const SizedBox(width: 16),

                  // --- LADO DERECHO: Toda la información ---
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. Título
                        Text(
                          service.title,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        
                        // 2. Ubicación con el Pin 📍 (Sustituye al tiempo)
                        Row(
                          children: [
                            Icon(Icons.location_on, size: 14, color: Colors.grey[500]),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                service.exactAddress ?? "A 2km, Col. Centro", // Si no hay, pone el de tu imagen
                                style: TextStyle(color: Colors.grey[500], fontSize: 13),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        
                        // 3. Precio y Botón
                        // 3. Precio y Botón
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // 👇 ENVOLVEMOS EL PRECIO EN UN FLEXIBLE PARA EVITAR EL OVERFLOW (RAYAS AMARILLAS)
                            Flexible(
                              child: Text(
                                "\$${service.basePrice.toStringAsFixed(0)} MXN",
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF10B981)), // Verde
                                overflow: TextOverflow.ellipsis, // Si no cabe, pone "..."
                              ),
                            ),
                            const SizedBox(width: 8), // Un pequeño respiro de separación
                            SizedBox(
                              height: 36,
                              child: ElevatedButton(
                                onPressed: () {},
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isUrgent ? const Color(0xFF1D04F8) : const Color(0xFFE0E7FF),
                                  foregroundColor: isUrgent ? Colors.white : const Color(0xFF1D04F8),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                ),
                                child: const Text("Ver Detalles", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // --- ETIQUETA "URGENTE" (Top Right) ---
            if (isUrgent)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFE4E6), // Rojito claro
                    borderRadius: BorderRadius.only(bottomLeft: Radius.circular(8)),
                  ),
                  child: const Text(
                    "URGENTE",
                    style: TextStyle(color: Color(0xFFE11D48), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}