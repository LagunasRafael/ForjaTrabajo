import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forja_trabajo/features/services/domain/entities/service_entity.dart';
import 'package:forja_trabajo/features/auth/presentation/providers/auth_provider.dart';
import 'package:forja_trabajo/features/services/presentation/screens/shared/service_detail_screen.dart';
import 'package:forja_trabajo/features/services/data/repositories/service_repository_impl.dart';
import 'package:forja_trabajo/features/services/presentation/providers/job_management_provider.dart'; 

class WorkerActiveJobCard extends ConsumerWidget {
  final ServiceEntity job;

  const WorkerActiveJobCard({super.key, required this.job});

  void _goToDetails(BuildContext context, WidgetRef ref) {
    final user = ref.read(authProvider).user;
    if (user == null) return;
    
    Navigator.push(
      context, 
      MaterialPageRoute(
        builder: (_) => ServiceDetailScreen(
          service: job, 
          currentUser: user, 
          categoryName: "En Curso"
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06), 
            blurRadius: 15, 
            offset: const Offset(0, 5),
          )
        ],
      ),
      // Envolvemos en Material transparente para que el InkWell haga su animación de pulsación
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _goToDetails(context, ref),
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
                    const SizedBox(height: 12),
                    _buildActions(context, ref),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🖼️ IMAGEN OPTIMIZADA PARA RENDIMIENTO
  Widget _buildImage(String url) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      child: Stack(
        children: [
          Image.network(
            url, 
            height: 140, 
            width: double.infinity, 
            fit: BoxFit.cover, 
            cacheWidth: 600, // 🚀 OPTIMIZACIÓN: Evita que el celular colapse por fotos gigantes
            errorBuilder: (_, __, ___) => Container(
              height: 140, 
              color: Colors.grey.shade200, 
              child: const Icon(Icons.image_not_supported, color: Colors.grey, size: 40)
            ),
          ),
          Positioned(
            top: 10, 
            right: 10, 
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), 
              decoration: BoxDecoration(
                color: const Color(0xFF10B981), 
                borderRadius: BorderRadius.circular(20),
              ), 
              child: const Text(
                "¡A TRABAJAR!", 
                style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitlePrice() {
    return Row(
      children: [
        Expanded(
          child: Text(
            job.title, 
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18), 
            maxLines: 1, 
            overflow: TextOverflow.ellipsis,
          ),
        ), 
        const SizedBox(width: 8), 
        Text(
          "\$${job.basePrice.toStringAsFixed(0)}", 
          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF10B981))
        ),
      ],
    );
  }

  Widget _buildLocation() {
    return Row(
      children: [
        const Icon(Icons.location_on, size: 14, color: Colors.grey), 
        const SizedBox(width: 4), 
        Expanded(
          child: Text(
            job.exactAddress ?? 'Remoto', 
            style: const TextStyle(color: Colors.grey), 
            maxLines: 1, 
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // 🕹️ BOTONES ESTRUCTURADOS
  Widget _buildActions(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        const Divider(height: 24),
        Row(
          children: [
            // Botón Contactar
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Chat en desarrollo..."))
                ), 
                icon: const Icon(Icons.chat_bubble_outline, size: 18, color: Color(0xFF10B981)), 
                label: const Text("Contactar", style: TextStyle(color: Color(0xFF10B981))), 
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF10B981)), 
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                ),
              ),
            ),
            const SizedBox(width: 12),
            
            // Botón Terminar
            // Botón Terminar
            Expanded(
              child: ElevatedButton.icon(
                // 👇 Si está en espera, desactivamos el botón (onPressed: null)
                onPressed: job.status == JobStatus.waiting_confirmation 
                    ? null 
                    : () => _handleCompleteJob(context, ref), 
                icon: Icon(
                    job.status == JobStatus.waiting_confirmation ? Icons.hourglass_top : Icons.check_circle_outline, 
                    size: 18
                ), 
                label: Text(
                    job.status == JobStatus.waiting_confirmation ? "Esperando al Cliente" : "Terminar"
                ), 
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981), 
                  foregroundColor: Colors.white, 
                  disabledBackgroundColor: Colors.grey.shade300, // Color gris si está desactivado
                  disabledForegroundColor: Colors.grey.shade600,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Lógica separada para el diálogo de confirmación (más limpio)
  Future<void> _handleCompleteJob(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context, 
      builder: (ctx) => AlertDialog(
        title: const Text('¿Trabajo terminado?'), 
        content: const Text('¿Confirmas que ya realizaste el servicio?'), 
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false), 
            child: const Text('No')
          ), 
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true), 
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)), 
            child: const Text('Sí, terminar', style: TextStyle(color: Colors.white))
          )
        ]
      )
    );

    if (confirm == true) {
      final success = await ref.read(serviceRepositoryProvider).completeService(job.id);
      if (success) {
        ref.invalidate(workerJobsProvider); // Refresca la lista
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("✅ Trabajo completado"), backgroundColor: Color(0xFF10B981))
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("❌ Error al finalizar"), backgroundColor: Colors.red)
          );
        }
      }
    }
  }
}