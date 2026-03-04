import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forja_trabajo/features/services/domain/entities/service_entity.dart';
import 'package:forja_trabajo/features/services/presentation/providers/service_list_provider.dart';
import 'package:forja_trabajo/features/services/data/repositories/service_repository_impl.dart';

// 👇 Importamos para poder navegar a los detalles
import 'package:forja_trabajo/features/auth/presentation/providers/auth_provider.dart';
import 'package:forja_trabajo/features/services/presentation/screens/shared/service_detail_screen.dart';

class ClientMatchedJobCard extends ConsumerWidget {
  final ServiceEntity service;

  const ClientMatchedJobCard({super.key, required this.service});

  // 🚀 LÓGICA: Navegar a los detalles al tocar la tarjeta
  void _goToDetails(BuildContext context, WidgetRef ref) {
    final user = ref.read(authProvider).user;
    if (user == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ServiceDetailScreen(
          service: service,
          currentUser: user,
          categoryName: "Servicio en Curso",
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imageUrl = (service.imageUrls.isNotEmpty)
        ? service.imageUrls.first
        : 'https://placehold.co/600x400/e2e8f0/64748b?text=Sin+Imagen';

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _goToDetails(context, ref), // 👈 Tocar para ver detalles
          child: Column(
            children: [
              _buildImage(imageUrl),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildTitlePrice(),
                    const SizedBox(height: 6),
                    _buildLocation(),
                    _buildActions(context, ref), // Botones de Chat y Finalizar
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage(String url) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        child: Stack(children: [
          Image.network(
            url, 
            height: 140, 
            width: double.infinity, 
            fit: BoxFit.cover,
            cacheWidth: 600, // 🚀 OPTIMIZACIÓN DE MEMORIA
            errorBuilder: (_, __, ___) => Container(height: 140, color: Colors.grey.shade200, child: const Icon(Icons.image_not_supported, color: Colors.grey, size: 40)),
          ),
          Positioned(
            top: 10, right: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(20)),
              child: const Text("EN PROCESO", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ),
        ]),
      );

  Widget _buildTitlePrice() => Row(children: [
        Expanded(child: Text(service.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18), maxLines: 1, overflow: TextOverflow.ellipsis)),
        const SizedBox(width: 8),
        Text("\$${service.basePrice.toStringAsFixed(0)}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
      ]);

  Widget _buildLocation() => Row(children: [
        const Icon(Icons.location_on, size: 14, color: Colors.grey),
        const SizedBox(width: 4),
        Expanded(child: Text(service.exactAddress ?? 'Ubicación remota', style: const TextStyle(color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis)),
      ]);

  Widget _buildActions(BuildContext context, WidgetRef ref) => Column(children: [
        const Divider(height: 24),
        Row(children: [
          _btn("Contactar", Icons.chat_bubble_outline, isOutlined: true, onPressed: () {
            // Lógica del chat (Pendiente)
          }),
          const SizedBox(width: 12),
          
          // 🛡️ BOTÓN INTELIGENTE (Doble Check)
          _btn(
            service.status == JobStatus.waiting_confirmation ? "Confirmar Fin" : "Esperando al Trabajador", 
            service.status == JobStatus.waiting_confirmation ? Icons.check_circle_outline : Icons.hourglass_empty, 
            color: service.status == JobStatus.waiting_confirmation ? Colors.green : Colors.orange, 
            
            // Si no está en waiting_confirmation, mandamos NULL para que se bloquee y se ponga gris
            onPressed: service.status == JobStatus.waiting_confirmation ? () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('¿Finalizar trabajo?'),
                  content: const Text('¿Confirmas que el servicio se ha completado?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
                    TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sí, finalizar')),
                  ],
                ),
              );

              if (confirm != true) return;

              final success = await ref.read(serviceRepositoryProvider).completeService(service.id);
              if (success) {
                ref.invalidate(myRequestsProvider);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Trabajo completado"), backgroundColor: Colors.green));
                }
              } else if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("❌ Error al finalizar")));
              }
            } : null, 
          ),
        ]),
      ]);

  // 👇 Helper optimizado para soportar botones apagados (null)
  Widget _btn(
    String label, 
    IconData icon, {
    required VoidCallback? onPressed, 
    bool isOutlined = false, 
    Color color = const Color(0xFF4F46E5)
  }) => Expanded(
        child: isOutlined
            ? OutlinedButton.icon(
                onPressed: onPressed, 
                icon: Icon(icon, size: 18, color: onPressed == null ? Colors.grey : color), 
                label: Text(label, style: TextStyle(color: onPressed == null ? Colors.grey : color)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: onPressed == null ? Colors.grey.shade300 : color),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                )
              )
            : ElevatedButton.icon(
                onPressed: onPressed, 
                icon: Icon(icon, size: 18), 
                label: Text(label), 
                style: ElevatedButton.styleFrom(
                  backgroundColor: color, 
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300, 
                  disabledForegroundColor: Colors.grey.shade600,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                )
              ),
      );
}