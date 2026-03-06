import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:forja_trabajo/features/services/domain/entities/service_entity.dart';
import 'package:forja_trabajo/features/services/presentation/providers/category_provider.dart';
import 'package:forja_trabajo/features/auth/presentation/providers/auth_provider.dart';
import 'package:forja_trabajo/features/services/presentation/screens/shared/service_detail_screen.dart';

class ServiceCard extends ConsumerWidget {
  final ServiceEntity service;
  const ServiceCard({super.key, required this.service});

  // --- Tus Helpers Visuales Originales ---
  IconData _getCategoryIcon(String categoryName) {
    final name = categoryName.toLowerCase();
    if (name.contains('font') || name.contains('plom') || name.contains('fuga'))
      return Icons.plumbing;
    if (name.contains('electr') || name.contains('luz'))
      return Icons.electric_bolt;
    if (name.contains('mueb') || name.contains('carp')) return Icons.chair_alt;
    if (name.contains('pint')) return Icons.format_paint;
    return Icons.home_repair_service;
  }

  Color _getIconBackgroundColor(String title) {
    final t = title.toLowerCase();
    if (t.contains('fuga')) return const Color(0xFFF3F4F6);
    if (t.contains('eléctr')) return const Color(0xFFFEF3C7);
    if (t.contains('pint')) return const Color(0xFFECFDF5);
    return const Color(0xFFEEF2FF);
  }

  Color _getIconColor(String title) {
    final t = title.toLowerCase();
    if (t.contains('fuga')) return const Color(0xFF2563EB);
    if (t.contains('eléctr')) return const Color(0xFFD97706);
    if (t.contains('pint')) return const Color(0xFF10B981);
    return const Color(0xFF4F46E5);
  }

  // --- Lógica de Navegación (CORREGIDA) ---
  void _onCardTap(BuildContext context, WidgetRef ref) {
    final authState = ref.read(authProvider);
    final currentUser = authState.user;

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Inicia sesión para ver detalles")));
      return;
    }

    final categoriesAsync = ref.read(categoryListProvider);
    String catName = "Servicio";

    categoriesAsync.whenData((cats) {
      // ✅ ARREGLO AQUÍ: Comparación segura de IDs para evitar el error de Null
      final found =
          cats.where((c) => c.id.toString() == service.categoryId.toString());
      if (found.isNotEmpty) {
        catName = found.first.name;
      }
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ServiceDetailScreen(
          service: service,
          currentUser: currentUser,
          categoryName: catName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoryListProvider);
    final isUrgent = service.title.toLowerCase().contains('urgente');
    final themeColor = _getIconColor(service.title);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isDark ? const Color(0xFF334155) : Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.15 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _onCardTap(context, ref),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- ICONO DINÁMICO ---
                    categoriesAsync.when(
                      data: (categories) {
                        String catName = "";
                        final found = categories.where((c) =>
                            c.id.toString() == service.categoryId.toString());
                        if (found.isNotEmpty) catName = found.first.name;

                        return Container(
                          width: 65,
                          height: 65,
                          decoration: BoxDecoration(
                            color: _getIconBackgroundColor(service.title),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                              _getCategoryIcon(
                                  catName.isEmpty ? service.title : catName),
                              color: themeColor,
                              size: 32),
                        );
                      },
                      loading: () => Container(
                          width: 65,
                          height: 65,
                          decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(12))),
                      error: (_, __) => Container(
                          width: 65,
                          height: 65,
                          child: const Icon(Icons.error, color: Colors.grey)),
                    ),

                    const SizedBox(width: 16),

                    // --- CONTENIDO ---
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          categoriesAsync.when(
                            data: (categories) {
                              String catName = "Servicio General";
                              final found = categories.where((c) =>
                                  c.id.toString() ==
                                  service.categoryId.toString());
                              if (found.isNotEmpty) catName = found.first.name;

                              return Text(
                                catName.toUpperCase(),
                                style: TextStyle(
                                    color: themeColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.8),
                              );
                            },
                            loading: () => const SizedBox(height: 10),
                            error: (_, __) => const SizedBox(),
                          ),
                          const SizedBox(height: 4),
                          Text(service.title,
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: theme.textTheme.bodyLarge?.color ??
                                      const Color(0xFF111827),
                                  height: 1.2),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.location_on,
                                  size: 14, color: Colors.grey[400]),
                              const SizedBox(width: 4),
                              Expanded(
                                  child: Text(
                                      service.exactAddress ??
                                          "Ubicación remota",
                                      style: TextStyle(
                                          color: Colors.grey[500],
                                          fontSize: 13),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("\$${service.basePrice.toStringAsFixed(0)}",
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF10B981))),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                    color: isUrgent
                                        ? const Color(0xFF1D04F8)
                                        : const Color(0xFFF3F4F6),
                                    borderRadius: BorderRadius.circular(8)),
                                child: Text("Ver Detalles",
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        color: isUrgent
                                            ? Colors.white
                                            : Colors.black87)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // --- ETIQUETA URGENTE ---
              if (isUrgent)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFE4E6),
                      borderRadius: BorderRadius.only(
                          topRight: Radius.circular(16),
                          bottomLeft: Radius.circular(16)),
                    ),
                    child: const Text("URGENTE",
                        style: TextStyle(
                            color: Color(0xFFE11D48),
                            fontSize: 10,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
