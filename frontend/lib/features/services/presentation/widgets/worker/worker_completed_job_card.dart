import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forja_trabajo/features/services/domain/entities/service_entity.dart';
import 'package:forja_trabajo/features/services/presentation/widgets/service_status_chip.dart';
import 'package:forja_trabajo/features/services/data/repositories/service_repository_impl.dart';
import 'package:forja_trabajo/features/services/presentation/providers/job_management_provider.dart';
import 'package:forja_trabajo/features/profile/presentation/widgets/review_dialog.dart' as forja_review;
import 'package:forja_trabajo/features/profile/presentation/screens/user_profile_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WorkerCompletedJobCard extends ConsumerWidget {
  final ServiceEntity job;

  const WorkerCompletedJobCard({super.key, required this.job});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface, 
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        job.title,
                        style: const TextStyle(
                          fontSize: 17, 
                          fontWeight: FontWeight.bold, 
                          color: Color(0xFF6B7280) // Gris azulado profesional
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        job.status == JobStatus.cancelled
                            ? "Cancelado el ${_formatDate(job.createdAt)}"
                            : "Finalizado el ${_formatDate(job.createdAt)}",
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ),
                // 🚀 Usamos el Chip que ya tienes
                ServiceStatusChip(status: job.status.toString().split('.').last),
              ],
            ),
            
            _buildClientInfo(context),
            
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1, thickness: 1),
            ),

            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                  onPressed: () => _handleDeleteFromHistory(context, ref),
                  tooltip: 'Eliminar de mi historial',
                ),
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.payments_outlined, size: 18, color: Colors.grey),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          job.status == JobStatus.cancelled
                              ? "Precio pactado: \$${job.basePrice.toStringAsFixed(0)}"
                              : "Ganancia: \$${job.basePrice.toStringAsFixed(0)}",
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF4B5563)
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (job.status != JobStatus.cancelled)
                  job.alreadyReviewed
                      ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? const Color(0xFF1E293B)
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            "Ya calificaste",
                            style: TextStyle(
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.grey.shade400
                                  : Colors.grey,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        )
                      : TextButton.icon(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (dialogContext) => ProviderScope(
                                parent: ProviderScope.containerOf(context),
                                child: forja_review.ReviewDialog(
                                  jobId: job.id,
                                  revieweeName: job.authorName ?? 'el cliente',
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.star_outline, size: 16, color: Color(0xFF6366F1)),
                          label: const Text(
                            "Calificar",
                            style: TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.bold)
                          ),
                        ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }

  Widget _buildClientInfo(BuildContext context) {
    final clientName = job.authorName ?? "Cliente";
    final clientId = job.clientId;
    return GestureDetector(
      onTap: () {
        if (clientId.isNotEmpty) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => UserProfileScreen(userId: clientId),
            ),
          );
        }
      },
      child: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Row(
          children: [
            CircleAvatar(
              radius: 12,
              backgroundImage: job.profilePictureUrl != null && job.profilePictureUrl!.isNotEmpty
                  ? NetworkImage(job.profilePictureUrl!)
                  : null,
              child: job.profilePictureUrl == null || job.profilePictureUrl!.isEmpty
                  ? const Icon(Icons.person, size: 12)
                  : null,
            ),
            const SizedBox(width: 6),
            Text(
              "Cliente: $clientName",
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleDeleteFromHistory(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar del historial'),
        content: const Text('¿Eliminar este servicio de tu historial?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Eliminar', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      if (token.isEmpty) return;
      final success = await ref.read(serviceRepositoryProvider).hideFromHistory(job.id, token);
      if (success && context.mounted) {
        ref.invalidate(workerJobsProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Eliminado del historial'), behavior: SnackBarBehavior.floating),
        );
      }
    }
  }
}