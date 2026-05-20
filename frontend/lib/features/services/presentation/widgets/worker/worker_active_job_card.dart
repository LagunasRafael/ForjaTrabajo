import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forja_trabajo/features/services/domain/entities/service_entity.dart';
import 'package:forja_trabajo/features/auth/presentation/providers/auth_provider.dart';
import 'package:forja_trabajo/features/services/presentation/screens/shared/service_detail_screen.dart';
import 'package:forja_trabajo/features/services/presentation/providers/job_management_provider.dart'; 
import 'package:forja_trabajo/features/services/presentation/providers/service_list_provider.dart';

import 'package:forja_trabajo/features/services/domain/usecases/jobs/complete_job_usecase.dart';
import 'package:forja_trabajo/features/services/domain/usecases/jobs/cancel_job_usecase.dart'; 
import 'package:forja_trabajo/features/chat/presentation/providers/chat_provider.dart';
import 'package:forja_trabajo/features/chat/presentation/screens/shared_chat_screen.dart';

import 'package:forja_trabajo/features/chat/presentation/providers/chat_list_provider.dart';
import 'package:forja_trabajo/features/services/presentation/screens/shared/widgets/shared_job_widgets.dart';

class WorkerActiveJobCard extends ConsumerWidget {
  final ServiceEntity job;
  const WorkerActiveJobCard({super.key, required this.job});

  void _goToDetails(BuildContext context, WidgetRef ref) {
    final user = ref.read(authProvider).user;
    if (user == null) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => ServiceDetailScreen(service: job, currentUser: user, categoryName: "En Curso")));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => _goToDetails(context, ref),
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 15, offset: const Offset(0, 5))],
        ),
        child: Column(
          children: [
            // 🧱 LEGO 1: IMAGEN + MENÚ
            SharedJobImage(
              imageUrls: job.imageUrls,
              badgeText: "¡A TRABAJAR!",
              badgeColor: const Color(0xFF10B981),
              floatingMenu: SharedCancelMenu(
                jobId: job.id,
                onCancelSuccess: () {
                  ref.invalidate(workerJobsProvider);
                  ref.invalidate(serviceListProvider);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // 🧱 LEGO 2: INFO
                  SharedJobInfo(title: job.title, price: job.basePrice, location: job.exactAddress),
                  
                  // 🚧 BOTONES DEL TRABAJADOR
                  _WorkerActiveActions(job: job),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// WIDGET PRIVADO PARA LOS BOTONES
// ==========================================
class _WorkerActiveActions extends ConsumerStatefulWidget {
  final ServiceEntity job;

  const _WorkerActiveActions({
    required this.job,
  });

  @override
  ConsumerState<_WorkerActiveActions> createState() => _WorkerActiveActionsState();
}

class _WorkerActiveActionsState extends ConsumerState<_WorkerActiveActions> {
  bool _isOpeningChat = false;

  Future<void> _openChat(BuildContext context) async {
    final requestId = widget.job.requestId;
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
            myRole: 'worker',
            service: {
              'id': widget.job.id,
              'title': widget.job.title,
            },
            otherUserName: widget.job.authorName,
            otherUserAvatarUrl: widget.job.profilePictureUrl,
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
    final isCompleting = ref.watch(completingJobProvider(widget.job.id));
    
    // 1. Solo evaluamos el estado real que viene de la base de datos
    final isWaiting = widget.job.status == JobStatus.waiting_confirmation;

    return Column(
      children: [
        const Divider(height: 24),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: (isCompleting || _isOpeningChat) ? null : () => _openChat(context),
                icon: _isOpeningChat
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF10B981)))
                    : const Icon(Icons.chat_bubble_outline, size: 18, color: Color(0xFF10B981)),
                label: const Text(
                  "Contactar",
                  style: TextStyle(color: Color(0xFF10B981)),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF10B981)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                // 2. Si está esperando o cargando, se deshabilita (null)
                onPressed: (isWaiting || isCompleting)
                    ? null
                    : () => _handleComplete(context, ref),

                icon: isCompleting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Icon(
                        isWaiting
                            ? Icons.hourglass_top
                            : Icons.check_circle_outline,
                        size: 18,
                      ),

                // 3. Cambiamos el texto según el estado real
                label: Text(isWaiting ? "Esperando al Cliente" : "Terminar"),

                style: ElevatedButton.styleFrom(
                  backgroundColor: isWaiting ? Colors.orange : const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                  disabledForegroundColor: Colors.grey.shade600,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _handleComplete(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Trabajo terminado?'),
        content: const Text(
          '¿Confirmas que ya realizaste el servicio? Se notificará al cliente para liberar el pago.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
            ),
            child: const Text(
              'Sí, terminar',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      ref.read(completingJobProvider(widget.job.id).notifier).state = true;

      // 4. Ejecutamos tu UseCase (Igual que en el cliente)
      final success = await ref.read(completeJobUseCaseProvider).execute(widget.job.id);

      ref.read(completingJobProvider(widget.job.id).notifier).state = false;

      if (success && context.mounted) {
        ref.invalidate(workerJobsProvider);
        ref.invalidate(myRequestsProvider);
        ref.invalidate(serviceListProvider);
        ref.invalidate(chatListProvider);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ Trabajo completado. Esperando confirmación."),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      } else if (context.mounted) {
         // 5. Agregamos un mensaje de error por si el backend falla
         ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("❌ Error al procesar la solicitud."),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}