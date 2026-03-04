import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forja_trabajo/features/services/domain/entities/service_entity.dart';

// 👇 Imports requeridos para la navegación y modal
import 'package:forja_trabajo/features/auth/presentation/providers/auth_provider.dart';
import 'package:forja_trabajo/features/services/presentation/screens/shared/service_detail_screen.dart';
import 'package:forja_trabajo/features/services/presentation/screens/worker/worker_apply_modal.dart';

class WorkerPendingJobCard extends ConsumerWidget {
  final ServiceEntity job;

  const WorkerPendingJobCard({super.key, required this.job});

  // 🚀 LÓGICA: Navegar a los detalles al tocar la tarjeta
  void _goToDetails(BuildContext context, WidgetRef ref) {
    final user = ref.read(authProvider).user;
    if (user == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ServiceDetailScreen(
          service: job,
          currentUser: user,
          categoryName: "Postulación Pendiente",
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imageUrl = (job.imageUrls.isNotEmpty)
        ? job.imageUrls.first
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImage(imageUrl),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTitlePrice(),
                    const SizedBox(height: 6),
                    _buildLocationAndDate(),
                    _buildActions(context, ref), // Botones de Editar y Retirar
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🖼️ IMAGEN CON ERROR BUILDER (Para que no salgan grises si falla)
  Widget _buildImage(String url) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        child: Stack(children: [
          Image.network(
            url, 
            height: 140, 
            width: double.infinity, 
            fit: BoxFit.cover,
            cacheWidth: 600,
            errorBuilder: (_, __, ___) => Container(
              height: 140, 
              width: double.infinity, 
              color: Colors.grey[200], 
              child: const Icon(Icons.image_not_supported, color: Colors.grey, size: 40)
            ),
          ),
          Positioned(
            top: 10, right: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: Colors.orange.shade400, borderRadius: BorderRadius.circular(20)),
              child: const Text("ESPERANDO RESPUESTA", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ),
        ]),
      );

  Widget _buildTitlePrice() => Row(children: [
        Expanded(
          child: Text(
            job.title, 
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          )
        ),
        const SizedBox(width: 8),
        Text(
          "\$${job.basePrice.toStringAsFixed(0)}", 
          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF10B981)) // Verde trabajador
        ),
      ]);

  Widget _buildLocationAndDate() => Row(children: [
        const Icon(Icons.location_on, size: 14, color: Colors.grey),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            "Postulado: ${_formatDate(job.createdAt)} • ${job.exactAddress ?? 'Ubicación remota'}", 
            style: const TextStyle(color: Colors.grey, fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          )
        ),
      ]);

  Widget _buildActions(BuildContext context, WidgetRef ref) => Column(children: [
        const Divider(height: 24),
        Row(children: [
          // Botón de Editar (Azul)
          _btn(
            "Editar Propuesta", 
            Icons.edit, 
            color: const Color(0xFF4F46E5), 
            onPressed: () {
              showWorkerApplyModal(
                context, 
                ref, 
                job,
                existingMessage: job.description, 
                existingPrice: job.basePrice,     
                requestId: job.id, 
              );
            }
          ),
          const SizedBox(width: 12),
          // Botón de Retirar (Rojo Outlined)
          _btn(
            "Retirar", 
            Icons.delete_outline, 
            isOutlined: true,
            color: const Color(0xFFEF4444),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Próximamente: Retirar propuesta")));
            }
          ),
        ]),
      ]);

  // Widget de botón auxiliar
  Widget _btn(String label, IconData icon, {required VoidCallback onPressed, bool isOutlined = false, Color color = const Color(0xFF4F46E5)}) => Expanded(
        child: isOutlined
            ? OutlinedButton.icon(
                onPressed: onPressed, 
                icon: Icon(icon, size: 16, color: color), 
                label: Text(label, style: TextStyle(color: color, fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: color),
                  padding: const EdgeInsets.symmetric(vertical: 10)
                ),
              )
            : ElevatedButton.icon(
                onPressed: onPressed, 
                icon: Icon(icon, size: 16), 
                label: Text(label, style: const TextStyle(fontSize: 12)), 
                style: ElevatedButton.styleFrom(
                  backgroundColor: color, 
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10)
                ),
              ),
      );

  String _formatDate(DateTime date) {
    final meses = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
    return "${date.day} de ${meses[date.month - 1]}";
  }
}