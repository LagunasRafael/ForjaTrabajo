import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forja_trabajo/features/services/domain/entities/service_entity.dart';
import 'package:forja_trabajo/features/services/presentation/providers/category_provider.dart';
import 'package:forja_trabajo/features/auth/presentation/providers/auth_provider.dart';
import 'package:forja_trabajo/features/services/presentation/screens/shared/service_detail_screen.dart';
import 'package:forja_trabajo/core/network/api_client.dart';

class ServiceCard extends ConsumerWidget {
  final ServiceEntity service;

  const ServiceCard({super.key, required this.service});

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

  void _onCardTap(BuildContext context, WidgetRef ref, String categoryName) {
    final currentUser = ref.read(authProvider).user;

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Inicia sesión para ver detalles")));
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ServiceDetailScreen(
          service: service,
          currentUser: currentUser,
          categoryName: categoryName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final isUrgent = service.title.toLowerCase().contains('urgente');
    final themeColor = _getIconColor(service.title);
    final bgColor = _getIconBackgroundColor(service.title);

    // 🧠 Resolución reactiva de categoría
    final categoriesAsync = ref.watch(categoryListProvider);
    String catName = "Servicio";

    if (categoriesAsync is AsyncData) {
      final cats = categoriesAsync.value!;
      final found =
          cats.where((c) => c.id.toString() == service.categoryId.toString());
      catName = found.isNotEmpty ? found.first.name : "General";
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isDark ? const Color(0xFF334155) : Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cardWidth = constraints.maxWidth;

          final padding = (cardWidth * 0.04).clamp(12.0, 20.0);
          final iconContainerSize = (cardWidth * 0.16).clamp(50.0, 80.0);
          final iconSize = iconContainerSize * 0.5;
          final titleFontSize = (cardWidth * 0.04).clamp(14.0, 18.0);
          final priceFontSize = (cardWidth * 0.045).clamp(16.0, 20.0);
          final categoryFontSize = (cardWidth * 0.028).clamp(10.0, 12.0);
          final addressFontSize = (cardWidth * 0.035).clamp(12.0, 14.0);
          final gapSmall = (cardWidth * 0.012).clamp(4.0, 8.0);
          final gapMedium = (cardWidth * 0.025).clamp(8.0, 14.0);
          final gapLarge = (cardWidth * 0.035).clamp(12.0, 18.0);
          final iconGap = (cardWidth * 0.04).clamp(12.0, 20.0);

          return Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _onCardTap(context, ref, catName),
              child: Stack(
                children: [
                  Padding(
                    padding: EdgeInsets.all(padding),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: iconContainerSize,
                          height: iconContainerSize,
                          decoration: BoxDecoration(
                            color: categoriesAsync.isLoading
                                ? (isDark ? Colors.white10 : Colors.grey[100])
                                : (isDark
                                    ? themeColor.withOpacity(0.2)
                                    : bgColor),
                            borderRadius:
                                BorderRadius.circular(iconContainerSize * 0.18),
                          ),
                          child: categoriesAsync.isLoading
                              ? const Center(
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2))
                              : Icon(
                                  _getCategoryIcon(catName),
                                  color: isDark
                                      ? themeColor.withAlpha(200)
                                      : themeColor,
                                  size: iconSize,
                                ),
                        ),
                        SizedBox(width: iconGap),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                catName.toUpperCase(),
                                style: TextStyle(
                                  color: themeColor,
                                  fontSize: categoryFontSize,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              SizedBox(height: gapSmall),
                              Text(
                                service.title,
                                style: TextStyle(
                                  fontSize: titleFontSize,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF111827),
                                  height: 1.2,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: gapMedium),
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
                                          fontSize: addressFontSize),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: gapLarge),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "\$${service.basePrice.toStringAsFixed(0)}",
                                    style: TextStyle(
                                      fontSize: priceFontSize,
                                      fontWeight: FontWeight.w900,
                                      color: const Color(0xFF10B981),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: isUrgent
                                          ? const Color(0xFF1D04F8)
                                          : (isDark
                                              ? Colors.white10
                                              : const Color(0xFFF3F4F6)),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      "Ver Detalles",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: categoryFontSize,
                                        color: isUrgent
                                            ? Colors.white
                                            : (isDark
                                                ? Colors.white70
                                                : Colors.black87),
                                      ),
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
                  if (isUrgent)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: const BoxDecoration(
                          color: Color(0xFFFFE4E6),
                          borderRadius: BorderRadius.only(
                              topRight: Radius.circular(16),
                              bottomLeft: Radius.circular(16)),
                        ),
                        child: Text("URGENTE",
                            style: TextStyle(
                                color: Color(0xFFE11D48),
                                fontSize: categoryFontSize,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: _ServiceMenu(
                        serviceId: service.id,
                        serviceOwnerId: service.clientId),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ServiceMenu extends StatelessWidget {
  final String serviceId;
  final String? serviceOwnerId;

  const _ServiceMenu({required this.serviceId, this.serviceOwnerId});

  Future<void> _handleReport(BuildContext context) async {
    final reasonController = TextEditingController();
    String selectedReason = 'inappropriate_content';

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Row(children: [
            Icon(Icons.flag, color: Colors.orange),
            SizedBox(width: 8),
            Text('Reportar publicación')
          ]),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('¿Por qué quieres reportar esta publicación?'),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedReason,
                  decoration: const InputDecoration(
                      labelText: 'Motivo', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'spam', child: Text('Spam')),
                    DropdownMenuItem(
                        value: 'inappropriate_content',
                        child: Text('Contenido inapropiado')),
                    DropdownMenuItem(value: 'scam', child: Text('Estafa')),
                    DropdownMenuItem(value: 'harassment', child: Text('Acoso')),
                    DropdownMenuItem(
                        value: 'fake_profile', child: Text('Perfil falso')),
                    DropdownMenuItem(value: 'other', child: Text('Otro')),
                  ],
                  onChanged: (v) {
                    if (v != null) setDialogState(() => selectedReason = v);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: reasonController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                      hintText: 'Describe lo sucedido (opcional)...',
                      border: OutlineInputBorder()),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Enviar reporte',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );

    if (result == true && context.mounted) {
      try {
        await ApiClient().reportUser(
          reportedUserId: serviceOwnerId ?? '',
          reportedServiceId: serviceId,
          reason: selectedReason,
          description:
              reasonController.text.isNotEmpty ? reasonController.text : null,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Reporte enviado. Un administrador lo revisará.'),
              backgroundColor: Colors.green),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, size: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (val) {
        if (val == 'report') _handleReport(context);
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'report',
          child: Row(children: [
            Icon(Icons.flag_outlined, size: 20, color: Colors.orange),
            SizedBox(width: 10),
            Text('Reportar publicación'),
          ]),
        ),
      ],
    );
  }
}
