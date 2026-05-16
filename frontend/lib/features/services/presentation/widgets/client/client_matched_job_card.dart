import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forja_trabajo/features/services/domain/entities/service_entity.dart';
import 'package:forja_trabajo/features/auth/presentation/providers/auth_provider.dart';
import 'package:forja_trabajo/features/services/presentation/screens/shared/service_detail_screen.dart';
import 'package:forja_trabajo/features/services/presentation/screens/shared/widgets/shared_job_widgets.dart';
import 'package:forja_trabajo/features/services/domain/usecases/jobs/complete_job_usecase.dart';
import 'package:forja_trabajo/features/services/presentation/providers/service_list_provider.dart';
import 'package:forja_trabajo/features/chat/presentation/providers/chat_provider.dart';
import 'package:forja_trabajo/features/chat/presentation/screens/shared_chat_screen.dart';
import 'package:forja_trabajo/features/profile/presentation/widgets/review_dialog.dart' as forja_review;
import 'package:forja_trabajo/features/services/presentation/screens/client/checkout_screen.dart';

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
              badgeText: isWaiting ? "LISTO PARA REVISIÓN" : (service.status == JobStatus.matched ? "PAGO PENDIENTE" : "EN PROCESO"),
              badgeColor: isWaiting ? const Color(0xFF10B981) : (service.status == JobStatus.matched ? Colors.red : Colors.orange),
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

class _ClientMatchedActions extends ConsumerStatefulWidget {
  final ServiceEntity service;
  final bool isWaiting;
  
  const _ClientMatchedActions({required this.service, required this.isWaiting});

  @override
  ConsumerState<_ClientMatchedActions> createState() => _ClientMatchedActionsState();
}

class _ClientMatchedActionsState extends ConsumerState<_ClientMatchedActions> {
  bool _isOpeningChat = false;

  Future<void> _openChat(BuildContext context) async {
    final requestId = widget.service.requestId;
    if (requestId == null || requestId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No se puede abrir el chat: sin postulación asociada"), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isOpeningChat = true);

    try {
      final repository = ref.read(chatRepositoryProvider);
      final conversationId = await repository.getOrCreateConversation(requestId);

      if (context.mounted) {
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => SharedChatScreen(
            conversationId: conversationId,
            myRole: 'client',
            service: {'title': widget.service.title},
            otherUserName: widget.service.workerName,
            otherUserAvatarUrl: widget.service.workerImageUrl,
          ),
        ));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error abriendo el chat: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isOpeningChat = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCompleting = ref.watch(completingJobProvider(widget.service.id));

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
              isLoading: _isOpeningChat,
              onPressed: (isCompleting || _isOpeningChat) ? null : () => _openChat(context),
            ),
            const SizedBox(width: 12),
            if (widget.service.status == JobStatus.matched && !widget.isWaiting)
              _btn(
                context: context,
                label: "Pagar ahora",
                icon: Icons.payment,
                color: const Color(0xFF7B4DFF),
                onPressed: () => _handlePayment(context),
              )
            else
              _btn(
                context: context,
                label: widget.isWaiting ? "Confirmar Fin" : "En curso...",
                icon: widget.isWaiting ? Icons.check_circle_outline : Icons.hourglass_empty,
                color: widget.isWaiting ? const Color(0xFF10B981) : Colors.orange,
                isLoading: isCompleting,
                onPressed: (widget.isWaiting && !isCompleting) 
                  ? () => _handleComplete(context) 
                  : null,
              ),
          ],
        ),
      ],
    );
  }

  void _handlePayment(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CheckoutScreen(
          jobId: widget.service.id,
          amount: widget.service.basePrice.toDouble(),
        ),
      ),
    );
  }

  Future<void> _handleComplete(BuildContext context) async {
    final confirm = await _showConfirmDialog(context);
    if (confirm != true) return;

    ref.read(completingJobProvider(widget.service.id).notifier).state = true;
    
    try {
      final success = await ref.read(completeJobUseCaseProvider).execute(widget.service.id);
      
      if (success && context.mounted) {
        ref.invalidate(myRequestsProvider); 
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ Trabajo finalizado exitosamente."), 
            backgroundColor: Color(0xFF10B981)
          )
        );

        // 🔥 MOSTRAR DIÁLOGO DE RESEÑA DESPUÉS DE FINALIZAR 🔥
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => ProviderScope(
            parent: ProviderScope.containerOf(context),
            child: forja_review.ReviewDialog(
              jobId: widget.service.id, // Suponiendo que service.id mapea al jobId en la API de Flutter
              revieweeName: widget.service.workerName ?? 'el trabajador',
            ),
          ),
        );
      }
    } finally {
      ref.read(completingJobProvider(widget.service.id).notifier).state = false;
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
            icon: isLoading
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : Icon(icon, size: 18, color: onPressed == null ? Colors.grey : color),
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