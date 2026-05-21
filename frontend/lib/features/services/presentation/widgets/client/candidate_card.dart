import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forja_trabajo/features/chat/presentation/providers/chat_provider.dart';
import 'package:forja_trabajo/features/chat/presentation/providers/chat_list_provider.dart';
import 'package:forja_trabajo/features/chat/presentation/screens/shared_chat_screen.dart';
import 'package:forja_trabajo/features/services/presentation/providers/service_request_provider.dart';
import 'package:forja_trabajo/features/services/presentation/providers/service_list_provider.dart';
import 'package:forja_trabajo/features/services/presentation/providers/service_offers_provider.dart';
import 'package:forja_trabajo/features/services/presentation/providers/nav_providers.dart';
import 'package:forja_trabajo/features/auth/presentation/providers/auth_provider.dart';
import 'package:forja_trabajo/features/notifications/presentation/providers/notification_provider.dart';
import 'package:forja_trabajo/features/profile/presentation/screens/user_profile_screen.dart';
import 'package:forja_trabajo/features/services/presentation/providers/service_list_provider.dart';

class CandidateCard extends ConsumerStatefulWidget {
  final dynamic offer;
  final String serviceId;
  final String? serviceTitle;
  const CandidateCard({super.key, required this.offer, required this.serviceId, this.serviceTitle});
  
  @override
  ConsumerState<CandidateCard> createState() => _CandidateCardState();
}

class _CandidateCardState extends ConsumerState<CandidateCard> {
  bool _showInput = false;
  bool _isSendingOffer = false;
  final TextEditingController _offerController = TextEditingController();

  @override
  void dispose() {
    _offerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAccepting = ref.watch(isAcceptingProvider(widget.offer.id));

    // Resolve service details dynamically and robustly!
    final serviceAsync = ref.watch(serviceDetailProvider(widget.serviceId));
    final myRequestsAsync = ref.watch(myRequestsProvider);
    final serviceListAsync = ref.watch(serviceListProvider);
    
    final resolvedTitle = widget.serviceTitle ?? myRequestsAsync.maybeWhen(
      data: (list) {
        final match = list.where((s) => s.id == widget.serviceId);
        return match.isNotEmpty ? match.first.title : null;
      },
      orElse: () => null,
    ) ?? serviceListAsync.maybeWhen(
      data: (list) {
        final match = list.where((s) => s.id == widget.serviceId);
        return match.isNotEmpty ? match.first.title : null;
      },
      orElse: () => null,
    ) ?? serviceAsync.maybeWhen(
      data: (service) => service.title,
      orElse: () => null,
    );

    debugPrint('🔍 [CandidateCard] widget.serviceTitle: ${widget.serviceTitle} | widget.serviceId: ${widget.serviceId} | resolvedTitle: $resolvedTitle');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(20), 
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04), 
            blurRadius: 10, 
            offset: const Offset(0, 4)
          )
        ]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, 
        children: [
          _buildHeader(),
          _buildMessage(),
          _buildActions(isAccepting, resolvedTitle),
          if (_showInput) _buildCounterOfferInput(resolvedTitle),
        ]
      ),
    );
  }

  Widget _buildHeader() {
    final imgUrl = widget.offer.authorImageUrl; 
    final name = widget.offer.workerName ?? "Trabajador";
    final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : "U";
    final workerId = widget.offer.workerId?.toString();

    return GestureDetector(
      onTap: () {
        if (workerId != null) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => UserProfileScreen(userId: workerId),
            ),
          );
        }
      },
      child: Row(
      children: [
        CircleAvatar(
          radius: 24, 
          backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
          backgroundImage: (imgUrl != null && imgUrl.isNotEmpty) ? NetworkImage(imgUrl) : null,
          child: (imgUrl == null || imgUrl.isEmpty) 
              ? Text(initial, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4F46E5), fontSize: 18)) 
              : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            name, 
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), 
            maxLines: 1, 
            overflow: TextOverflow.ellipsis
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(color: const Color(0xFF10B981), borderRadius: BorderRadius.circular(10)),
          child: Text(
            "\$${widget.offer.proposedPrice?.toStringAsFixed(0) ?? '0'}", 
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)
          ),
        )
      ],
      ),
    );
  }

  Widget _buildMessage() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12), 
      padding: const EdgeInsets.all(12), 
      width: double.infinity,
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceVariant, borderRadius: BorderRadius.circular(12)),
      child: Text(
        "\"${widget.offer.description ?? 'Sin mensaje'}\"", 
        style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.black87, fontSize: 13)
      ),
    );
  }

  Widget _buildActions(bool isAccepting, String? resolvedTitle) {
    return Row(
      children: [
        // 💬 BOTÓN DE CHAT
        Container(
          decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceVariant, borderRadius: BorderRadius.circular(10)), 
          child: IconButton(
            icon: const Icon(Icons.chat_bubble_outline, size: 20),
            onPressed: isAccepting ? null : () => _handleOpenChat(resolvedTitle),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _btn("Contraoferta", const Color(0xFFEEF2FF), const Color(0xFF4F46E5), 
              isAccepting ? null : () => setState(() => _showInput = !_showInput))
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981), 
              foregroundColor: Colors.white, 
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), 
              padding: EdgeInsets.zero
            ), 
            onPressed: isAccepting ? null : _handleAccept, 
            child: isAccepting 
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                : Text(widget.offer.status == "accepted" ? "Pagar ahora" : "Aceptar", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))
          )
        ),
      ]
    );
  }

  Future<void> _handleOpenChat(String? resolvedTitle) async {
    try {
      final targetId = widget.offer.id;
      final chatId = await ref.read(chatDatasourceProvider).startOrGetChat(targetId);

      if (mounted) {
        ref.invalidate(chatListProvider);
        
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SharedChatScreen(
              conversationId: chatId,
              otherUserName: widget.offer.workerName, 
              otherUserAvatarUrl: widget.offer.authorImageUrl, 
              service: {
                'id': widget.serviceId,
                'title': resolvedTitle ?? 'Propuesta de trabajo',
              }, 
            ),
          ),
        );
        // Volver a refrescar al salir del chat por si se enviaron mensajes
        ref.invalidate(chatListProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("🚨 Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _btn(String lbl, Color bg, Color text, VoidCallback? onTap) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: bg, 
        foregroundColor: text, 
        elevation: 0, 
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), 
        padding: EdgeInsets.zero
      ), 
      onPressed: onTap, 
      child: Text(lbl, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))
    );
  }

  Widget _buildCounterOfferInput(String? resolvedTitle) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: TextFormField(
        controller: _offerController,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly], 
        decoration: InputDecoration(
          prefixText: "\$ ", 
          hintText: "00.00", 
          filled: true, 
          fillColor: Colors.white,
          suffixIcon: _isSendingOffer
            ? const Padding(
                padding: EdgeInsets.all(12.0),
                child: SizedBox(
                  width: 20, 
                  height: 20, 
                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF4F46E5))
                ),
              )
            : IconButton(
                icon: const Icon(Icons.send, color: Color(0xFF4F46E5)), 
                onPressed: () => _handleSendCounterOffer(resolvedTitle),
              ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12), 
            borderSide: BorderSide(color: Colors.grey.shade200)
          ),
        ),
      ),
    );
  }

  Future<void> _handleSendCounterOffer(String? resolvedTitle) async {
    final amountText = _offerController.text.trim();
    if (amountText.isEmpty) return;
    
    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Ingresa un monto válido"), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isSendingOffer = true);
    
    try {
      final targetId = widget.offer.id;
      final chatId = await ref.read(chatDatasourceProvider).startOrGetChat(targetId);
      
      await ref.read(chatDatasourceProvider).sendOffer(chatId, amount);
      
      if (mounted) {
        setState(() {
          _isSendingOffer = false;
          _showInput = false;
        });
        _offerController.clear();
        
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                "Contraoferta enviada",
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF4F46E5)),
              ),
              backgroundColor: const Color(0xFFF0F0F0).withOpacity(1),
              behavior: SnackBarBehavior.floating,
              margin: EdgeInsets.only(
                bottom: MediaQuery.of(context).size.height - 750,
                left: 24,
                right: 24,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        
        ref.invalidate(chatListProvider);
        
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SharedChatScreen(
              conversationId: chatId,
              otherUserName: widget.offer.workerName, 
              otherUserAvatarUrl: widget.offer.authorImageUrl, 
              service: {
                'id': widget.serviceId,
                'title': resolvedTitle ?? 'Propuesta de trabajo',
              }, 
            ),
          ),
        );
        ref.invalidate(chatListProvider);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSendingOffer = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al enviar oferta: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _handleAccept() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: Color(0xFF6366F1), size: 24),
            SizedBox(width: 10),
            Text('¿Aceptar propuesta?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Al aceptar esta propuesta:',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.chat_outlined, size: 18, color: Color(0xFF6366F1)),
                SizedBox(width: 8),
                Expanded(child: Text(
                  'Tendrás un chat disponible para acordar los detalles del servicio con el trabajador.',
                  style: TextStyle(fontSize: 13))),
              ],
            ),
            SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.payments_outlined, size: 18, color: Color(0xFFF59E0B)),
                SizedBox(width: 8),
                Expanded(child: Text(
                  'Deberás ir a "Mis Trabajos" y realizar el pago para iniciar formalmente el trabajo.',
                  style: TextStyle(fontSize: 13))),
              ],
            ),
            SizedBox(height: 14),
            Text('¿Deseas continuar?',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Aceptar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      ref.read(isAcceptingProvider(widget.offer.id).notifier).state = true;
      try {
        await ref.read(serviceRequestProvider.notifier).acceptWorker(widget.offer.id);

        ref.invalidate(myRequestsProvider);
        ref.invalidate(offersListProvider(widget.serviceId));
        ref.invalidate(serviceDetailProvider(widget.serviceId));
      } catch (_) {}
      ref.read(isAcceptingProvider(widget.offer.id).notifier).state = false;

    if (success && mounted) {
      Navigator.pop(context); 
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Contratado"), backgroundColor: Color(0xFF10B981))
      );
    }
  }

  @override
  void dispose() {
    _counterOfferController.dispose();
    super.dispose();
  }
}