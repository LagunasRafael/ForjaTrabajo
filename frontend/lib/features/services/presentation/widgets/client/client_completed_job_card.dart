import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forja_trabajo/features/services/domain/entities/service_entity.dart';
import 'package:forja_trabajo/features/auth/presentation/providers/auth_provider.dart';
import 'package:forja_trabajo/features/services/presentation/screens/shared/service_detail_screen.dart';
import 'package:forja_trabajo/features/profile/presentation/widgets/review_dialog.dart' as forja_review;
import 'package:forja_trabajo/features/payments/presentation/screens/invoices_screen.dart';
// 🚀 Legos universales
import 'package:forja_trabajo/features/services/presentation/screens/shared/widgets/shared_job_widgets.dart';
import 'package:forja_trabajo/features/profile/presentation/screens/user_profile_screen.dart';
class ClientCompletedJobCard extends ConsumerWidget {
  final ServiceEntity service;
  const ClientCompletedJobCard({super.key, required this.service});
  void _goToDetails(BuildContext context, WidgetRef ref) {
    final user = ref.read(authProvider).user;
    if (user == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ServiceDetailScreen(
          service: service,
          currentUser: user,
          categoryName: "Historial",
        ),
      ),
    );
  }
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 🎨 LÓGICA DE TUS COMPAÑEROS: Soporte para Modo Oscuro
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        // 🎨 FUSIÓN: Borde adaptable según el tema
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : Colors.grey.shade200
        ), 
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.1 : 0.03), 
            blurRadius: 10, 
            offset: const Offset(0, 4)
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _goToDetails(context, ref),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🧱 TU LEGO: Imagen con Badge de Completado o Cancelado
              SharedJobImage(
                imageUrls: service.imageUrls,
                badgeText: service.status == JobStatus.cancelled ? "CANCELADO" : "COMPLETADO",
                badgeColor: service.status == JobStatus.cancelled ? Colors.red : const Color(0xFF10B981), // Rojo o Verde
              ),
              
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTitleAndStars(isDark),
                    const SizedBox(height: 6),
                    _buildWorkerInfo(context),
                     const SizedBox(height: 12),
                    _buildDescription(isDark),
                    
                    // 🚧 ACCIONES: Lógica aislada en su propia clase (sólo si no está cancelado)
                    const SizedBox(height: 16),
                    _ClientCompletedActions(service: service),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildTitleAndStars(bool isDark) {
    return Text(
      service.title,
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 16,
        color: isDark ? Colors.white : Colors.black87,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
  Widget _buildWorkerInfo(BuildContext context) {
    final workerName = service.workerName ?? "Trabajador";
    final workerId = service.workerId;
    return GestureDetector(
      onTap: () {
        if (workerId != null && workerId.isNotEmpty) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => UserProfileScreen(userId: workerId),
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
              backgroundImage: service.workerImageUrl != null && service.workerImageUrl!.isNotEmpty
                  ? NetworkImage(service.workerImageUrl!)
                  : null,
              child: service.workerImageUrl == null || service.workerImageUrl!.isEmpty
                  ? const Icon(Icons.person, size: 12)
                  : null,
            ),
            const SizedBox(width: 6),
            Text(
              "Trabajador: $workerName",
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildDescription(bool isDark) {
    return Text(
      service.summary ?? service.description,
      style: TextStyle(
        color: isDark ? Colors.white70 : Colors.grey.shade700, // 🎨 Color adaptable
        fontSize: 13, 
        height: 1.4
      ),
      maxLines: 2, overflow: TextOverflow.ellipsis,
    );
  }
}
// =======================================================
// LÓGICA DE BOTONES AISLADA (Mantenemos tu Clean Architecture)
// =======================================================
class _ClientCompletedActions extends ConsumerWidget {
  final ServiceEntity service;
  
  const _ClientCompletedActions({required this.service});
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
        service.alreadyReviewed
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
            : Container(
                height: 48, width: 48,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: IconButton(
                  icon: const Icon(Icons.star_rate_rounded, color: Colors.black54),
                  onPressed: () => _handleRateWorker(context, ref),
                ),
              )
      ],
    );
  }
  Future<void> _handleRequestInvoice(BuildContext context, WidgetRef ref) async {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const InvoicesScreen()),
    );
  }
  Future<void> _handleRateWorker(BuildContext context, WidgetRef ref) async {
    showDialog(
      context: context,
      builder: (dialogContext) => ProviderScope(
        parent: ProviderScope.containerOf(context),
        child: forja_review.ReviewDialog(
          jobId: service.requestId ?? service.id,
          revieweeName: service.workerName ?? 'el trabajador',
        ),
      ),
    );
  }
}