import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forja_trabajo/features/chat/domain/entities/message_entity.dart';
import 'package:forja_trabajo/features/chat/presentation/widgets/negotiation_card.dart';
import 'package:forja_trabajo/features/auth/presentation/providers/auth_provider.dart';
import 'package:forja_trabajo/features/chat/presentation/providers/chat_provider.dart';
import 'package:forja_trabajo/features/chat/presentation/providers/chat_list_provider.dart'; // 👈 Agregado
import 'package:forja_trabajo/features/chat/presentation/widgets/chat_bubble.dart';
import 'package:forja_trabajo/features/chat/presentation/widgets/chat_app_bar.dart';
import 'package:forja_trabajo/features/chat/presentation/widgets/chat_input_area.dart';
import 'package:forja_trabajo/features/chat/presentation/widgets/offer_bottom_sheet.dart';
import 'package:forja_trabajo/core/network/notification_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:forja_trabajo/features/services/presentation/screens/shared/service_detail_screen.dart';
import 'package:forja_trabajo/features/services/domain/entities/service_entity.dart';
import 'package:forja_trabajo/core/utils/formatters.dart';

class SharedChatScreen extends ConsumerStatefulWidget {
  final String conversationId;
  final String? otherUserName;
  final String? otherUserAvatarUrl;
  final String? otherUserId;
  final String? myRole; 
  final dynamic service;

  const SharedChatScreen({
    super.key, 
    required this.conversationId,
    this.otherUserName,
    this.otherUserAvatarUrl,
    this.otherUserId,
    this.myRole, 
    this.service,
  });

  @override
  ConsumerState<SharedChatScreen> createState() => _SharedChatScreenState();
}

class _SharedChatScreenState extends ConsumerState<SharedChatScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  bool _isNearBottom() {
    if (!_scrollController.hasClients) return true;
    return _scrollController.offset <= 50;
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients && !_isNearBottom()) {
      _scrollController.animateTo(
        0.0,
        curve: Curves.easeOut,
        duration: const Duration(milliseconds: 300),
      );
    }
  }

  MessageEntity? _getLastOffer(List<MessageEntity> messages) {
    try {
      return messages.firstWhere((m) => m.messageType == 'offer');
    } catch (_) {
      return null;
    }
  }

  void _showDisputeDialog(BuildContext parentContext) {
    final reasonController = TextEditingController();
    
    showDialog(
      context: parentContext,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.gavel, color: Colors.red),
              SizedBox(width: 8),
              Text('Abrir Disputa', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Describe el motivo de la disputa. Un administrador revisará el caso.'),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Ej. El trabajador no completó el servicio...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                final reason = reasonController.text.trim();
                if (reason.isEmpty) return;
                
                final scaffoldMessenger = ScaffoldMessenger.of(parentContext);
                
                Navigator.pop(dialogContext); // Cerrar diálogo
                
                try {
                  await ref
                      .read(chatProvider(widget.conversationId).notifier)
                      .openDispute(reason);

                  if (mounted) {
                    scaffoldMessenger.showSnackBar(
                      SnackBar(
                        content: const Text(
                          'Disputa abierta. Un administrador se pondrá en contacto pronto.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Color(0xFF4F46E5)),
                        ),
                        backgroundColor: const Color(0xFFF0F0F0).withOpacity(1),
                        behavior: SnackBarBehavior.floating,
                        margin: EdgeInsets.only(
                          bottom: MediaQuery.of(context).size.height - 835,
                          left: 24,
                          right: 24,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    scaffoldMessenger.showSnackBar(
                      SnackBar(
                        content: const Text(
                          'Error al abrir la disputa. Intenta de nuevo.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Color(0xFF4F46E5)),
                        ),
                        backgroundColor: const Color(0xFFF0F0F0).withOpacity(1),
                        behavior: SnackBarBehavior.floating,
                        margin: EdgeInsets.only(
                          bottom: MediaQuery.of(context).size.height - 835,
                          left: 24,
                          right: 24,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                }
              },
              child: const Text('Enviar Disputa', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // 🔔 Escuchar eventos de notificación para refrescar en tiempo real (Resolución de Admin o Fin de Trabajo)
    ref.listen<AsyncValue<RemoteMessage>>(notificationEventProvider, (previous, next) {
      next.whenData((message) {
        final type = message.data['type'] ?? '';
        if (type == 'job_completed' || type == 'job_cancelled' || type == 'dispute_resolved') {
          debugPrint('🔄 [ChatScreen] Refrescando por resolución: $type');
          ref.invalidate(chatListProvider);
          ref.invalidate(chatProvider(widget.conversationId));
        }
      });
    });

    final messages = ref.watch(chatProvider(widget.conversationId));
    // Auto-scroll al recibir mensajes nuevos si el usuario está cerca del fondo
    ref.listen(chatProvider(widget.conversationId), (prev, next) {
      if (prev != null && next.length > prev.length && prev.isNotEmpty && _isNearBottom()) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      }
    });
    final chatNotifier = ref.read(chatProvider(widget.conversationId).notifier);
    
    final isOtherUserTyping = ref.watch(chatTypingProvider(widget.conversationId));
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final myId = user?.id;
    final myRole = widget.myRole ?? user?.role ?? 'client';
    final isClient = myRole == 'client'; 
    
    // 🧠 ESTADO DE CARGA: Si el usuario no está listo, o no hay mensajes pero el WS no está conectado, estamos cargando
    final isInitialLoading = authState.status == 'loading' || (messages.isEmpty && !chatNotifier.isConnected);
    
    final lastOffer = _getLastOffer(messages);
    final isOfferAccepted = messages.any((m) => m.messageType == 'offer' && 
        (m.status.toLowerCase() == 'accept' || m.status.toLowerCase() == 'accepted'));
    
    // Detectar si el chat está cerrado desde la lista de chats
    final chatList = ref.watch(chatListProvider);
    final thisChat = chatList.maybeWhen(
      data: (chats) {
        try {
          return chats.firstWhere((c) => c.id == widget.conversationId);
        } catch (_) {
          return null;
        }
      },
      orElse: () => null,
    );
    
    // El chat solo se bloquea totalmente si está cerrado (CERRADO/CLOSED)
    final isClosed = thisChat?.status?.toUpperCase() == 'CERRADO' || thisChat?.status?.toUpperCase() == 'CLOSED';
    final closedReason = thisChat?.closedReason;
    
    // ¿El servicio ya está en proceso con alguien? (MATCHED, etc)
    final sStatus = (thisChat?.serviceStatus ?? 'open').toLowerCase();
    final isMatched = sStatus != 'open' && sStatus != 'jobstatus.open';

    // Las ofertas se bloquean si el chat está cerrado, si ya hay trato aceptado aquí,
    // o si el servicio ya está en proceso (MATCHED)
    final canSendOffer = !isClosed && !isOfferAccepted && !isMatched;
    
    // El banner de negociación solo se muestra si hay una oferta pendiente y activa
    final hasActiveOffer = lastOffer != null && 
        lastOffer.status.toLowerCase() == 'pending' && 
        canSendOffer;
    final messageCount = messages.length;

    // Calcular el prefijo dinámico para el subtítulo del Chat
    final subtitlePrefix = isClosed
        ? "Chat finalizado"
        : (thisChat?.status?.toUpperCase() == 'EN DISPUTA')
            ? "En disputa por"
            : sStatus.contains('cancelled')
                ? "Cancelado:"
                : sStatus.contains('matched') 
                    ? "Trabaja en" 
                    : sStatus.contains('completed') 
                        ? "Trabajó en" 
                        : "Postulante a";

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: ChatAppBar(
        subtitlePrefix: subtitlePrefix,
        service: {
          'id': (widget.service is Map && widget.service['id'] != null) ? widget.service['id'] : thisChat?.serviceId,
          'title': (widget.service is Map && widget.service['title'] != null) ? widget.service['title'] : (thisChat?.serviceName ?? 'Servicio'),
        },
        otherUserName: widget.otherUserName,
        otherUserAvatarUrl: widget.otherUserAvatarUrl,
        otherUserId: widget.otherUserId,
        onOpenDispute: () => _showDisputeDialog(context),
        onTapService: () {
          final sId = (widget.service is Map && widget.service['id'] != null) ? widget.service['id'] : thisChat?.serviceId;
          final sTitle = (widget.service is Map && widget.service['title'] != null) ? widget.service['title'] : (thisChat?.serviceName ?? 'Servicio');
          
          if (sId != null && sId.isNotEmpty) {
            final currentUser = ref.read(authProvider).user;
            if (currentUser != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ServiceDetailScreen(
                    service: ServiceEntity(
                      id: sId,
                      title: sTitle,
                      description: '',
                      basePrice: 0.0,
                      categoryId: '',
                      clientId: '',
                      status: JobStatus.open,
                      isActive: true,
                      createdAt: DateTime.now(),
                    ),
                    currentUser: currentUser,
                    categoryName: 'Servicio',
                  ),
                ),
              );
            }
          }
        },
      ),
      body: Column(
        children: [
          Expanded(
            child: isInitialLoading
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,

                  ),
                )
              : messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 64, color: theme.colorScheme.onSurface.withOpacity(0.3)),
                        const SizedBox(height: 16),
                        const Text("No hay mensajes todavía", style: TextStyle(color: Colors.grey, fontSize: 16)),
                        const SizedBox(height: 8),
                        const Text("Di hola para comenzar", style: TextStyle(color: Colors.grey, fontSize: 14)),
                      ],
                    ),
                  )
                : NotificationListener<ScrollNotification>(
                    onNotification: (ScrollNotification scrollInfo) {
                      if (scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 100) {
                        ref.read(chatProvider(widget.conversationId).notifier).loadMoreMessages();
                      }
                      return false;
                    },
                    child: ListView.builder(
                      controller: _scrollController,
                      reverse: true,
                      padding: const EdgeInsets.all(16),
                      // 🔥 CLAVE: cacheExtent ayuda a mantener widgets renderizados
                      cacheExtent: 1000,
                      itemCount: messageCount + 1,
                      itemBuilder: (context, index) {
                        if (index == messageCount) {
                          final notifier = ref.read(chatProvider(widget.conversationId).notifier);
                          if (notifier.isLoadingMore) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 20),
                              child: Center(
                                child: SizedBox(
                                  width: 24, height: 24,
                                  child: CircularProgressIndicator(
                                    color: Color(0xFF4F46E5), 
                                    strokeWidth: 2
                                  )
                                )
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        }
                        
                        final m = messages[index];
                  final isMyMessage = m.senderId == myId;
                  
                  String displayTime = "";
                  final rawTime = m.createdAt;
                  
                  if (rawTime != null) {
                    try {
                      DateTime dateTime;
                      if (rawTime is DateTime) {
                        dateTime = rawTime.toLocal();
                      } else {
                        dateTime = DateTime.parse(rawTime.toString()).toLocal();
                      }
                      final hour = dateTime.hour > 12 ? dateTime.hour - 12 : (dateTime.hour == 0 ? 12 : dateTime.hour);
                      final minute = dateTime.minute.toString().padLeft(2, '0');
                      final period = dateTime.hour >= 12 ? 'PM' : 'AM';
                      displayTime = "$hour:$minute $period";
                    } catch (e) {
                      displayTime = rawTime.toString();
                    }
                  } else {
                    displayTime = "--:--";
                  }

                  Widget messageWidget;

                  if (m.messageType == 'offer') {
                    final isCurrentOffer = lastOffer != null && lastOffer.id == m.id;
                    messageWidget = NegotiationCard(
                      key: ValueKey("offer_${m.id}_${m.status}"),
                      message: m,
                      isMe: isMyMessage,
                      isClient: isClient,
                      conversationId: widget.conversationId,
                      serviceImageUrl: widget.service is Map ? widget.service['imageUrls']?.firstOrNull : null,
                      isProcessed: !isCurrentOffer,
                      time: displayTime,
                    );
                  } else {
                    messageWidget = ChatBubble(
                      key: ValueKey("bubble_${m.id}"),
                      text: m.content,
                      isMe: isMyMessage,
                      time: displayTime,
                      messageType: m.messageType,
                      status: m.status,
                      senderAvatarUrl: isMyMessage ? null : widget.otherUserAvatarUrl,
                      onRetry: () {
                        ref.read(chatProvider(widget.conversationId).notifier).resendMessage(m.id);
                      },
                    );
                  }

                  // Si es el último mensaje enviado y es mío, mostramos el estado abajo
                  if (index == 0 && isMyMessage) {
                    String statusText = "Enviado";
                    Color statusColor = Colors.grey.shade600;

                    if (m.status == 'sending') {
                      statusText = "Enviando...";
                      statusColor = const Color(0xFF4F46E5);
                    } else if (m.status == 'error') {
                      statusText = "Error al enviar";
                      statusColor = Colors.red;
                    } else if (m.status == 'pending') {
                      statusText = "Pendiente";
                      statusColor = Colors.orange;
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        messageWidget,
                        Padding(
                          padding: const EdgeInsets.only(top: 4, right: 12, bottom: 4),
                          child: Text(
                            statusText,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    );
                  }

                  return messageWidget;
                },
              ),
            ),
          ),
          
          if (isClient && hasActiveOffer)
            _buildNegotiationBanner(lastOffer.content.toString(), context),

          if (isOtherUserTyping) _buildTypingIndicator(),

          if (isClosed)
            _buildClosedBanner(closedReason, context),

          ChatInputArea(
            conversationId: widget.conversationId,
            isClient: isClient,
            canSendOffer: canSendOffer,
            isEnabled: !isClosed,
            onMessageSent: _scrollToBottom,
          ),
        ],
      ),
    );
  }

  String _translateClosedReason(String? reason) {
    switch (reason) {
      case 'WORKER_NOT_SELECTED': return 'Se seleccionó otro trabajador';
      case 'CLIENT_PAYMENT_TIMEOUT': return 'El pago no se realizó a tiempo';
      case 'APPLICATION_WITHDRAWN': return 'El trabajador retiró su postulación';
      case 'SERVICE_CANCELLED': return 'El servicio fue cancelado';
      case 'SERVICE_COMPLETED': return 'Servicio completado';
      case 'SERVICE_COMPLETED_AUTO': return 'Servicio completado automáticamente';
      case 'DISPUTE_RESOLVED': return 'Disputa resuelta';
      default: return 'Chat finalizado';
    }
  }

  Widget _buildClosedBanner(String? reason, BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.grey.shade100,
      child: Row(
        children: [
          const Icon(Icons.lock_outline, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _translateClosedReason(reason),
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.otherUserName != null ? "${widget.otherUserName} está escribiendo" : "Escribiendo",
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontStyle: FontStyle.italic),
          ),
          const SizedBox(width: 8),
          const SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF4F46E5)),
          ),
        ],
      ),
    );
  }

  Widget _buildNegotiationBanner(String amount, BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFC4B5FD)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                const Text("ESTADO DE NEGOCIACIÓN", style: TextStyle(color: Color(0xFF4F46E5), fontSize: 9, fontWeight: FontWeight.w900)),
                Text("Oferta actual: \$${Formatters.formatCurrency(amount)} MXN", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
          ElevatedButton.icon(
            onPressed: () {
              final scaffoldContext = context;
               showModalBottomSheet(
                 context: context,
                 isScrollControlled: true,
                 backgroundColor: Colors.transparent,
                 builder: (context) => OfferBottomSheet(
                   onSendOffer: (newAmount) async {
                     try {
                       await ref.read(chatProvider(widget.conversationId).notifier).sendOffer(newAmount);
                       if (scaffoldContext.mounted) {
                         ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                           SnackBar(
                             content: Text("✅ Contraoferta de \$${newAmount.toStringAsFixed(0)} enviada"),
                             backgroundColor: const Color(0xFF10B981),
                           ),
                         );
                       }
                     } catch (e) {
                       if (scaffoldContext.mounted) {
                         ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                           SnackBar(content: Text("🚨 Error: $e"), backgroundColor: Colors.red),
                         );
                       }
                     }
                   },
                 ),
               );
            },
            icon: const Icon(Icons.edit, size: 14, color: Colors.white),
            label: const Text("Modificar", style: TextStyle(fontSize: 12, color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          )
        ],
      ),
    );
  }
}