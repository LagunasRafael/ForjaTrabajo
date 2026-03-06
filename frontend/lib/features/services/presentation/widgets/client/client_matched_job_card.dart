import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forja_trabajo/features/services/domain/entities/service_entity.dart';
import 'package:forja_trabajo/features/auth/presentation/providers/auth_provider.dart';
import 'package:forja_trabajo/features/services/presentation/screens/shared/service_detail_screen.dart';
import 'package:forja_trabajo/features/services/presentation/screens/shared/widgets/shared_job_widgets.dart';

// Providers y UseCases
import 'package:forja_trabajo/features/services/domain/usecases/jobs/complete_job_usecase.dart';
import 'package:forja_trabajo/features/services/presentation/providers/service_list_provider.dart';
// 🚀 Asegúrate de importar el provider de "Mis Trabajos"
import 'package:forja_trabajo/features/services/presentation/providers/nav_providers.dart'; // O donde tengas myRequestsProvider


class ClientMatchedJobCard extends ConsumerWidget {
  final ServiceEntity service;
  const ClientMatchedJobCard({super.key, required this.service});

  void _goToDetails(BuildContext context, WidgetRef ref) {
    final user = ref.read(authProvider).user;
    if (user == null) return;
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => ServiceDetailScreen(service: service, currentUser: user, categoryName: "Servicio en Curso")
    ));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isWaiting = service.status == JobStatus.waiting_confirmation;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: InkWell(
        onTap: () => _goToDetails(context, ref),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            SharedJobImage(
              imageUrls: service.imageUrls,
              badgeText: isWaiting ? "LISTO PARA REVISIÓN" : "EN PROCESO",
              badgeColor: isWaiting ? Colors.green : Colors.orange,
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
                  // Separamos las acciones para mantener la tarjeta limpia
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

// =======================================================
// LÓGICA DE BOTONES Y USECASES AISLADA
// =======================================================
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
              onPressed: isCompleting ? null : () {}
            ),
            const SizedBox(width: 12),
            _btn(
              context: context,
              label: isWaiting ? "Confirmar Fin" : "En curso...",
              icon: isWaiting ? Icons.check_circle_outline : Icons.hourglass_empty,
              color: isWaiting ? Colors.green : Colors.orange,
              isLoading: isCompleting,
              onPressed: (isWaiting && !isCompleting) ? () => _handleComplete(context, ref) : null,
            ),
          ],
        ),
      ],
    );
  }

  // 1. EXTRAEMOS LA LÓGICA PRINCIPAL (Limpia y directa)
  Future<void> _handleComplete(BuildContext context, WidgetRef ref) async {
    final confirm = await _showConfirmDialog(context);
    if (confirm != true) return; // Si dice "No" o cierra, abortamos.

    // Iniciamos carga
    ref.read(completingJobProvider(service.id).notifier).state = true;
    
    // Ejecutamos UseCase
    final success = await ref.read(completeJobUseCaseProvider).execute(service.id);
    
    // Terminamos carga
    ref.read(completingJobProvider(service.id).notifier).state = false;

    // Consecuencias del éxito
    if (success && context.mounted) {
      // 🚀 OPTIMIZACIÓN: Refrescamos la lista del cliente (MyRequestsScreen)
      ref.invalidate(myRequestsProvider); 
      ref.invalidate(serviceListProvider);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Trabajo finalizado exitosamente."), backgroundColor: Colors.green)
      );
    }
  }

  // 2. EXTRAEMOS EL DIÁLOGO (Para no abultar el método principal)
  Future<bool?> _showConfirmDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Finalizar trabajo?'),
        content: const Text('¿Confirmas que el servicio se completó? Se cerrará el empleo y se liberará el pago.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true), 
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green), 
            child: const Text('Sí, finalizar', style: TextStyle(color: Colors.white))
          ),
        ],
      ),
    );
  }

  // 3. WIDGET DE BOTÓN GENÉRICO LIMPIO
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
            label: Text(label, style: const TextStyle(fontSize: 12)),
            style: ElevatedButton.styleFrom(
              backgroundColor: color, 
              foregroundColor: Colors.white, 
              disabledBackgroundColor: Colors.grey.shade300, 
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
            )
          ),
    );
  }
}