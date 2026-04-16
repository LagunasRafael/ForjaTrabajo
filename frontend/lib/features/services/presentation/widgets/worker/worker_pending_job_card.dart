import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forja_trabajo/features/services/presentation/screens/shared/widgets/shared_job_widgets.dart';
import 'package:forja_trabajo/features/services/domain/entities/service_entity.dart';
import 'package:forja_trabajo/features/services/presentation/providers/service_list_provider.dart';
import 'package:forja_trabajo/features/auth/presentation/providers/auth_provider.dart';
import 'package:forja_trabajo/features/services/presentation/screens/shared/service_detail_screen.dart';
import 'package:forja_trabajo/features/services/presentation/screens/worker/worker_apply_modal.dart';
import 'package:forja_trabajo/features/services/presentation/providers/service_request_provider.dart';
import 'package:forja_trabajo/features/services/presentation/providers/job_management_provider.dart';
import 'package:forja_trabajo/features/services/presentation/providers/service_offers_provider.dart';

class WorkerPendingJobCard extends ConsumerWidget {
  final ServiceEntity job;

  const WorkerPendingJobCard({super.key, required this.job});

  void _goToDetails(BuildContext context, WidgetRef ref) {
    final user = ref.read(authProvider).user;
    
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("🚨 Error: No se detectó tu sesión."), backgroundColor: Colors.red)
      );
      return;
    }

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

  String _formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => _goToDetails(context, ref),
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 15, offset: const Offset(0, 5))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🧱 LEGO 1: IMAGEN UNIVERSAL (Con etiqueta Naranja)
            SharedJobImage(
              imageUrls: job.imageUrls,
              badgeText: "ESPERANDO RESPUESTA",
              badgeColor: Colors.orange.shade400,
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🧱 LEGO 2: INFO UNIVERSAL (Le pasamos la fecha en el espacio de ubicación)
                  SharedJobInfo(
                    title: job.title, 
                    price: job.basePrice, 
                    location: "Postulado: ${_formatDate(job.createdAt)}"
                  ),
                  
                  // 🚧 BOTONES ESPECÍFICOS PARA TRABAJOS PENDIENTES
                  _WorkerPendingActions(job: job),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// MICRO-WIDGET: BOTONES Y LÓGICA DE PENDIENTES
// ==========================================
class _WorkerPendingActions extends ConsumerWidget {
  final ServiceEntity job;

  const _WorkerPendingActions({required this.job});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        const Divider(height: 24),
        Row(
          children: [
            _btn(
              "Editar Propuesta", 
              Icons.edit, 
              color: const Color(0xFF4F46E5),
              onPressed: () {
                showWorkerApplyModal(
                  context,
                  job,
                  existingMessage: job.description,
                  existingPrice: job.basePrice,
                  requestId: job.requestId ?? job.id,
                );
              }
            ),
            const SizedBox(width: 12),
            _btn(
              "Retirar",
              Icons.delete_outline,
              isOutlined: true,
              color: const Color(0xFFEF4444),
              onPressed: () => _showRetireConfirmation(context, ref),
            ),
          ],
        ),
      ],
    );
  }

  void _showRetireConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("¿Retirar postulación?"),
        content: const Text("Podrás volver a postularte más tarde si el cliente aún no ha cerrado el trato."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final targetId = job.requestId ?? job.id;
              final success = await ref.read(serviceRequestProvider.notifier).withdrawApplication(targetId);
              
              if (context.mounted && success) {
                Navigator.pop(ctx);
                
                // Limpieza de cachés
                ref.invalidate(workerJobsProvider); 
                ref.invalidate(serviceListProvider); 
                ref.invalidate(offersListProvider(job.id));
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("✅ Postulación retirada."))
                );
              }
            },
            child: const Text("Confirmar Retiro", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _btn(String label, IconData icon, {required VoidCallback onPressed, bool isOutlined = false, Color color = const Color(0xFF4F46E5)}) =>
      Expanded(
        child: isOutlined
            ? OutlinedButton.icon(
                onPressed: onPressed,
                icon: Icon(icon, size: 16, color: color),
                label: Text(label, style: TextStyle(color: color, fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: color),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              )
            : ElevatedButton.icon(
                onPressed: onPressed,
                icon: Icon(icon, size: 16),
                label: Text(label, style: const TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
      );
}