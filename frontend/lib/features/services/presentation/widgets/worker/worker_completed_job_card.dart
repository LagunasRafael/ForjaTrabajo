import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// 🚀 1. Usamos la Entidad real, no dynamic
import 'package:forja_trabajo/features/services/domain/entities/service_entity.dart';
import 'package:forja_trabajo/features/services/presentation/widgets/service_status_chip.dart';
import 'package:forja_trabajo/features/profile/presentation/widgets/review_dialog.dart' as forja_review;

class WorkerCompletedJobCard extends StatelessWidget {
  final ServiceEntity job;

  const WorkerCompletedJobCard({super.key, required this.job});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB), 
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
                        "Finalizado el ${_formatDate(job.createdAt)}",
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ),
                // 🚀 Usamos el Chip que ya tienes
                ServiceStatusChip(status: job.status.toString().split('.').last),
              ],
            ),
            
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1, thickness: 1),
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.payments_outlined, size: 18, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      "Ganancia: \$${(job.finalPrice ?? job.basePrice).toStringAsFixed(0)}",
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF4B5563)
                      ),
                    ),
                  ],
                ),
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
}