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
import 'package:forja_trabajo/features/payments/presentation/screens/invoices_screen.dart';
import 'package:forja_trabajo/features/payments/presentation/providers/payment_provider.dart';

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

            if (job.status != JobStatus.cancelled)
              _buildEarningsBreakdown(),
            if (job.status == JobStatus.cancelled)
              Row(
                children: [
                  const Icon(Icons.payments_outlined, size: 18, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    "Precio pactado: \$${job.basePrice.toStringAsFixed(0)}",
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4B5563),
                    ),
                  ),
                ],
              ),
              
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1, thickness: 1),
            ),
            
            _WorkerCompletedActions(job: job),
          ],
        ),
      ),
    ),
  );
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }

  Widget _buildEarningsBreakdown() {
    final original = job.basePrice;
    final platform = job.platformFee ?? (job.basePrice * 0.1);
    final stripe = job.stripeFee ?? 0.0;
    final net = job.netPayout ?? (original - platform - stripe);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Precio original", style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
              Text("\$${original.toStringAsFixed(2)}", style: const TextStyle(fontSize: 13, color: Color(0xFF4B5563))),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Comisión Forja", style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
              Text("-\$${platform.toStringAsFixed(2)}", style: const TextStyle(fontSize: 13, color: Color(0xFFDC2626))),
            ],
          ),
          if (stripe > 0) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Comisión Stripe", style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                Text("-\$${stripe.toStringAsFixed(2)}", style: const TextStyle(fontSize: 13, color: Color(0xFFDC2626))),
              ],
            ),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 6),
            child: Divider(height: 1, thickness: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Tu ganancia", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF16A34A))),
              Text("\$${net.toStringAsFixed(2)}", style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF16A34A))),
            ],
          ),
        ],
      ),
    );
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

class _WorkerCompletedActions extends ConsumerWidget {
  final ServiceEntity job;
  
  const _WorkerCompletedActions({required this.job});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _handleRequestInvoice(context, ref),
            icon: const Icon(Icons.receipt_long, size: 18),
            label: const Text("Pedir Factura", style: TextStyle(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB), 
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
          ),
        ),
        const SizedBox(width: 12),
        if (job.status != JobStatus.cancelled)
          job.alreadyReviewed
              ? Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF1E293B)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    "Ya calificaste",
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey.shade400
                          : Colors.grey,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )
              : SizedBox(
                  height: 48, width: 48,
                  child: IconButton(
                    icon: const Icon(Icons.star_rate_rounded, color: Colors.black54),
                    onPressed: () => _handleRateClient(context, ref),
                  ),
                ),
      ],
    );
  }

  Future<void> _handleRequestInvoice(BuildContext context, WidgetRef ref) async {
    try {
      final payments = await ref.read(paymentHistoryProvider.future);
      debugPrint("Pagos cargados: ${payments.length}");
      for (var p in payments) {
        debugPrint("- Pago: ID=${p.id}, serviceId=${p.serviceId}, jobId=${p.jobId}, amount=${p.amount}");
      }
      
      final payment = payments.where((p) => p.serviceId == job.id || p.jobId == job.id || p.jobId == job.requestId).firstOrNull;
      
      if (payment == null) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('El servicio fue cancelado o eliminado')),
        );
        return;
      }
      if (!context.mounted) return;
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => InvoiceDetailSheet(payment: payment),
      );
    } catch (e) {
      debugPrint("Error fetching payments: $e");
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar la factura: $e')),
      );
    }
  }

  Future<void> _handleRateClient(BuildContext context, WidgetRef ref) async {
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
  }
}
