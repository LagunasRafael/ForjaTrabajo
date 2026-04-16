import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forja_trabajo/features/services/domain/entities/service_entity.dart';
import 'package:forja_trabajo/features/auth/presentation/providers/auth_provider.dart';
import 'package:forja_trabajo/features/services/presentation/screens/shared/service_detail_screen.dart';
import 'package:forja_trabajo/features/services/presentation/screens/shared/widgets/shared_job_widgets.dart';
import 'package:forja_trabajo/features/services/domain/usecases/jobs/complete_job_usecase.dart';
import 'package:forja_trabajo/features/services/presentation/providers/service_list_provider.dart';

class ClientMatchedJobCard extends ConsumerWidget {
  final ServiceEntity service;
  const ClientMatchedJobCard({super.key, required this.service});

  void _goToDetails(BuildContext context, WidgetRef ref) {
    final user = ref.read(authProvider).user;
    if (user == null) return;
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => ServiceDetailScreen(
        service: service, 
        currentUser: user, 
        categoryName: "Servicio en Curso"
      )
    ));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isWaiting = service.status == JobStatus.waiting_confirmation;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : Colors.transparent,
          width: 1
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.06),
            blurRadius: 15,
            offset: const Offset(0, 5)
          )
        ],
      ),
      child: InkWell(
        onTap: () => _goToDetails(context, ref),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            SharedJobImage(
              imageUrls: service.imageUrls,
              badgeText: isWaiting ? "LISTO PARA REVISIÓN" : "EN PROCESO",
              badgeColor: isWaiting ? const Color(0xFF10B981) : Colors.orange,
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  SharedJobInfo(
                    title: service.title, 
                    price: service.basePrice, 
                    location: service.exactAddress ?? 'Ubicación remota'
                  ),
                  _ClientMatchedActions(service: service, isWaiting: isWaiting),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClientMatchedActions extends ConsumerWidget {
  final ServiceEntity service;
  final bool isWaiting;
  
  const _ClientMatchedActions({required this.service, required this.isWaiting});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCompleting = ref.watch(completingJobProvider(service.id));

    return Column(
      children: [
        const Divider(height: 24),
        Row(
          children: [
            _btn(
              context: context, 
              label: "Chat", 
              icon: Icons.chat_bubble_outline, 
              isOutlined: true, 
              onPressed: isCompleting ? null : () {
              }
            ),
            const SizedBox(width: 12),
            _btn(
              context: context,
              label: isWaiting ? "Confirmar Fin" : "En curso...",
              icon: isWaiting ? Icons.check_circle_outline : Icons.hourglass_empty,
              color: isWaiting ? const Color(0xFF10B981) : Colors.orange,
              isLoading: isCompleting,
              onPressed: (isWaiting && !isCompleting) 
                ? () => _handleComplete(context, ref) 
                : null,
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _handleComplete(BuildContext context, WidgetRef ref) async {
    final confirm = await _showConfirmDialog(context);
    if (confirm != true) return;

    ref.read(completingJobProvider(service.id).notifier).state = true;
    
    try {
      final success = await ref.read(completeJobUseCaseProvider).execute(service.id);
      
      if (success && context.mounted) {
        ref.invalidate(myRequestsProvider); 
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ Trabajo finalizado exitosamente."), 
            backgroundColor: Color(0xFF10B981)
          )
        );
      }
    } finally {
      ref.read(completingJobProvider(service.id).notifier).state = false;
    }
  }

  Future<bool?> _showConfirmDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('¿Finalizar trabajo?'),
        content: const Text('¿Confirmas que el servicio se completó correctamente? Se cerrará el empleo.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true), 
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
            ), 
            child: const Text('Sí, finalizar', style: TextStyle(color: Colors.white))
          ),
        ],
      ),
    );
  }

  Widget _btn({
    required BuildContext context, 
    required String label, 
    required IconData icon, 
    VoidCallback? onPressed, 
    bool isOutlined = false, 
    Color color = const Color(0xFF4F46E5), 
    bool isLoading = false
  }) {
    return Expanded(
      child: isOutlined 
        ? OutlinedButton.icon(
            onPressed: onPressed, 
            icon: Icon(icon, size: 18, color: onPressed == null ? Colors.grey : color),
            label: Text(label, style: TextStyle(color: onPressed == null ? Colors.grey : color, fontSize: 12)),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: onPressed == null ? Colors.grey.shade300 : color), 
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
            )
          )
        : ElevatedButton.icon(
            onPressed: onPressed, 
            icon: isLoading 
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Icon(icon, size: 18), 
            label: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: color, 
              foregroundColor: Colors.white, 
              disabledBackgroundColor: Colors.grey.shade300, 
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0
            )
          ),
    );
  }
}