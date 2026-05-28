import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forja_trabajo/features/services/domain/entities/service_entity.dart';
import 'package:forja_trabajo/features/services/presentation/widgets/service_status_chip.dart';
import 'package:forja_trabajo/features/services/presentation/widgets/delete_from_history_button.dart';
import 'package:forja_trabajo/features/services/presentation/providers/job_management_provider.dart';
import 'package:forja_trabajo/features/services/presentation/providers/service_list_provider.dart';
import 'package:forja_trabajo/features/profile/presentation/widgets/review_dialog.dart' as forja_review;
import 'package:forja_trabajo/features/profile/presentation/screens/user_profile_screen.dart';
import 'package:forja_trabajo/features/auth/presentation/providers/auth_provider.dart';
import 'package:forja_trabajo/features/services/presentation/screens/shared/service_detail_screen.dart';

class WorkerCompletedJobCard extends ConsumerWidget {
  final ServiceEntity job;

  const WorkerCompletedJobCard({super.key, required this.job});

  void _goToDetails(BuildContext context, WidgetRef ref) {
    final user = ref.read(authProvider).user;
    if (user == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ServiceDetailScreen(
          service: job,
          currentUser: user,
          categoryName: job.status == JobStatus.cancelled ? "Cancelado" : "Finalizado",
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => _goToDetails(context, ref),
      child: Container(
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
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ServiceStatusChip(status: job.status.toString().split('.').last),
                    const SizedBox(width: 4),
                      PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: Colors.grey),
                      onSelected: (value) {
                        if (value == 'delete') {
                          // Aquí va la misma lógica que ya usabas al borrar
                          ref.read(deletedServiceIdsProvider.notifier).update(
                            (state) => {...state, job.id},
                          );

                          ref.invalidate(workerJobsProvider);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem<String>(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                                size: 20,
                              ),
                              SizedBox(width: 10),
                              Text(
                                "Borrar del historial",
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            
            _buildClientInfo(context),
            
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1, thickness: 1),
            ),

            Row(
              children: [

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

}