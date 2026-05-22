import 'dart:async';
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
import 'package:forja_trabajo/features/services/presentation/providers/job_management_provider.dart';
import 'package:forja_trabajo/features/chat/presentation/providers/chat_list_provider.dart';
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
    final isPaid = service.hasPaid;
    final isMatched = service.status == JobStatus.matched;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    String badgeText;
    Color badgeColor;
    if (isWaiting) {
      badgeText = "LISTO PARA REVISIÓN";
      badgeColor = const Color(0xFF10B981);
    } else if (isMatched && isPaid) {
      badgeText = "PAGADO";
      badgeColor = const Color(0xFF10B981);
    } else if (isMatched) {
      badgeText = "PAGO PENDIENTE";
      badgeColor = Colors.red;
    } else {
      badgeText = "EN PROCESO";
      badgeColor = Colors.orange;
    }

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
              badgeText: badgeText,
              badgeColor: badgeColor,
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  SharedJobInfo(
                    title: service.title, 
                    price: service.finalPrice ?? service.basePrice, 
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
  String _countdown = '';
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void didUpdateWidget(covariant _ClientMatchedActions oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.service.status != widget.service.status ||
        oldWidget.service.hasPaid != widget.service.hasPaid) {
      _startCountdown();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _timer?.cancel();
    _updateCountdown();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateCountdown());
  }

  void _updateCountdown() {
    DateTime? deadline;
    if (widget.service.status == JobStatus.matched && !widget.service.hasPaid) {
      deadline = widget.service.paymentDueAt;
    } else if (widget.service.status == JobStatus.waiting_confirmation) {
      deadline = widget.service.autoReleaseAt;
    }

    if (deadline == null) {
      if (_countdown.isNotEmpty) setState(() => _countdown = '');
      return;
    }

    final remaining = deadline.difference(DateTime.now());
    if (remaining.isNegative) {
      setState(() => _countdown = '');
      _timer?.cancel();
      return;
    }

    final hours = remaining.inHours;
    final minutes = remaining.inMinutes.remainder(60);
    final seconds = remaining.inSeconds.remainder(60);
    if (hours > 0) {
      setState(() => _countdown = '${hours}h ${minutes.toString().padLeft(2, '0')}m ${seconds.toString().padLeft(2, '0')}s');
    } else if (minutes > 0) {
      setState(() => _countdown = '${minutes}m ${seconds.toString().padLeft(2, '0')}s');
    } else {
      setState(() => _countdown = '${seconds}s');
    }
  }

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
            service: {
              'id': widget.service.id,
              'title': widget.service.title,
            },
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
    final isPaid = widget.service.hasPaid;
    final isMatched = widget.service.status == JobStatus.matched;

    String label;
    IconData icon;
    VoidCallback? onPressed;
    Color color;

    if (isMatched && !isPaid) {
      label = "Pagar";
      icon = Icons.payment;
      onPressed = () => _handlePayment(context);
      color = const Color(0xFF7B4DFF);
    } else if (isMatched && isPaid) {
      label = "Esperando al trabajador...";
      icon = Icons.lock_outline;
      onPressed = null;
      color = Colors.grey;
    } else {
      label = "Confirmar finalización";
      icon = Icons.check_circle_outline;
      onPressed = isCompleting ? null : () => _handleComplete(context);
      color = const Color(0xFF10B981);
    }

    return Column(
      children: [
        if (_countdown.isNotEmpty)
          _buildCountdownBanner(context),
        const Divider(height: 24),
        Row(
          children: [
            _btn(
              context: context, 
              label: "Chat", 
              icon: Icons.chat_bubble_outline, 
              isOutlined: true, 
              isLoading: _isOpeningChat,
              onPressed: (_isOpeningChat) ? null : () => _openChat(context),
            ),
            const SizedBox(width: 12),
            _btn(
              context: context,
              label: label,
              icon: icon,
              color: color,
              isLoading: isCompleting,
              onPressed: onPressed,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCountdownBanner(BuildContext context) {
    final isMatched = widget.service.status == JobStatus.matched;
    final isWaiting = widget.service.status == JobStatus.waiting_confirmation;

    String message;
    Color bgColor;
    Color textColor;

    if (isMatched && !widget.service.hasPaid) {
      message = "Tiempo restante para pagar";
      bgColor = Colors.red.shade50;
      textColor = Colors.red.shade800;
    } else if (isWaiting) {
      message = "Tiempo restante para confirmación automática";
      bgColor = Colors.orange.shade50;
      textColor = Colors.orange.shade800;
    } else {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.access_time, size: 18, color: textColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(message,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: textColor)),
                const SizedBox(height: 2),
                Text(_countdown,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handlePayment(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CheckoutScreen(
          jobId: widget.service.id,
          workerId: widget.service.workerId,
          amount: (widget.service.finalPrice ?? widget.service.basePrice).toDouble(),
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
        ref.invalidate(workerJobsProvider);
        ref.invalidate(chatListProvider);        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ Trabajo finalizado exitosamente."), 
            backgroundColor: Color(0xFF10B981)
          )
        );

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => ProviderScope(
            parent: ProviderScope.containerOf(context),
            child: forja_review.ReviewDialog(
              jobId: widget.service.id,
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