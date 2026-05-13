import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forja_trabajo/features/services/domain/entities/service_entity.dart';
import 'package:forja_trabajo/features/auth/presentation/providers/auth_provider.dart';
import 'package:forja_trabajo/features/services/presentation/screens/shared/service_detail_screen.dart';
import 'package:forja_trabajo/features/profile/presentation/widgets/review_dialog.dart' as forja_review;

// 🚀 Legos universales
import 'package:forja_trabajo/features/services/presentation/screens/shared/widgets/shared_job_widgets.dart';

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
              // 🧱 TU LEGO: Imagen con Badge de Completado
              SharedJobImage(
                imageUrls: service.imageUrls,
                badgeText: "COMPLETADO",
                badgeColor: const Color(0xFF10B981), // Verde éxito
              ),
              
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTitleAndStars(isDark),
                    const SizedBox(height: 6),
                    _buildWorkerInfo(),
                    const SizedBox(height: 12),
                    _buildDescription(isDark),
                    const SizedBox(height: 16),
                    
                    // 🚧 ACCIONES: Lógica aislada en su propia clase
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            service.title,
            style: TextStyle(
              fontWeight: FontWeight.bold, 
              fontSize: 16, 
              color: isDark ? Colors.white : Colors.black87 // 🎨 Color adaptable
            ),
            maxLines: 1, overflow: TextOverflow.ellipsis,
          ),
        ),
        Row(
          children: List.generate(
            5, (index) => const Icon(Icons.star, color: Color(0xFFFBBF24), size: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildWorkerInfo() {
    return Row(
      children: [
        const Icon(Icons.person, size: 14, color: Colors.grey),
        const SizedBox(width: 6),
        Text(
          service.authorName ?? "Trabajador asignado",
          style: const TextStyle(color: Colors.grey, fontSize: 13),
        ),
      ],
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
        
        Container(
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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Funcionalidad de factura en desarrollo..."))
    );
  }

  Future<void> _handleRateWorker(BuildContext context, WidgetRef ref) async {
    showDialog(
      context: context,
      builder: (dialogContext) => ProviderScope(
        parent: ProviderScope.containerOf(context),
        child: forja_review.ReviewDialog(
          jobId: service.id,
          revieweeName: service.workerName ?? 'el trabajador',
        ),
      ),
    );
  }
}