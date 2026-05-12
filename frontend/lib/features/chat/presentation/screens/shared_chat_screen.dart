import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forja_trabajo/features/chat/domain/entities/message_entity.dart';
import 'package:forja_trabajo/features/chat/presentation/widgets/negotiation_card.dart';
import 'package:forja_trabajo/features/auth/presentation/providers/auth_provider.dart';
import 'package:forja_trabajo/features/chat/presentation/providers/chat_provider.dart';
import 'package:forja_trabajo/features/chat/presentation/widgets/chat_bubble.dart';
import 'package:forja_trabajo/features/chat/presentation/widgets/chat_app_bar.dart';
import 'package:forja_trabajo/features/chat/presentation/widgets/chat_input_area.dart';
import 'package:forja_trabajo/features/chat/presentation/widgets/offer_bottom_sheet.dart';

class SharedChatScreen extends ConsumerStatefulWidget {
  final String conversationId;
  final String? otherUserName;
  final String? otherUserAvatarUrl;
  final String? myRole; 
  final dynamic service;

  const SharedChatScreen({
    super.key, 
    required this.conversationId,
    this.otherUserName,
    this.otherUserAvatarUrl,
    this.myRole, 
    this.service,
  });

  @override
  ConsumerState<SharedChatScreen> createState() => _SharedChatScreenState();
}

class _SharedChatScreenState extends ConsumerState<SharedChatScreen> {
  final ScrollController _scrollController = ScrollController();
  
  // Ya no usamos _prevMaxScrollExtent para esto

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      if (_scrollController.offset > 0) {
        _scrollController.animateTo(
          0.0,
          curve: Curves.easeOut,
          duration: const Duration(milliseconds: 300),
        );
      }
    }
  }

  MessageEntity? _getLastOffer(List<MessageEntity> messages) {
    try {
      return messages.firstWhere((m) => m.messageType == 'offer');
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatProvider(widget.conversationId));
    final isOtherUserTyping = ref.watch(chatTypingProvider(widget.conversationId));
    final user = ref.watch(authProvider).user;
    final myId = user?.id;
    final myRole = widget.myRole ?? user?.role ?? 'client';
    final isClient = myRole == 'client'; 
    
    final lastOffer = _getLastOffer(messages);
    final isOfferAccepted = messages.any((m) => m.messageType == 'offer' && 
        (m.status.toLowerCase() == 'accept' || m.status.toLowerCase() == 'accepted'));
    final canSendOffer = !isOfferAccepted;
    final hasActiveOffer = lastOffer != null && canSendOffer;
    final messageCount = messages.length;



    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: ChatAppBar(
        service: widget.service,
        otherUserName: widget.otherUserName,
        otherUserAvatarUrl: widget.otherUserAvatarUrl,
      ),
      body: Column(
        children: [
          Expanded(
            child: NotificationListener<ScrollNotification>(
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

                  if (m.messageType == 'offer') {
                    final isCurrentOffer = lastOffer != null && lastOffer.id == m.id;
                    return NegotiationCard(
                      key: ValueKey("offer_${m.id}_${m.status}"),
                      message: m,
                      isMe: isMyMessage,
                      isClient: isClient,
                      conversationId: widget.conversationId,
                      serviceImageUrl: widget.service is Map ? widget.service['imageUrls']?.firstOrNull : null,
                      isProcessed: !isCurrentOffer,
                      time: displayTime,
                    );
                  }
                  
                  return ChatBubble(
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
                },
              ),
            ),
          ),
          
          if (isClient && hasActiveOffer)
            _buildNegotiationBanner(lastOffer.content.toString(), context),

          if (isOtherUserTyping) _buildTypingIndicator(),

          ChatInputArea(
            conversationId: widget.conversationId,
            isClient: isClient,
            canSendOffer: canSendOffer,
            onMessageSent: _scrollToBottom,
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
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F3FF),
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
                Text("Oferta actual: \$$amount MXN", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
          ElevatedButton.icon(
            onPressed: () {
               showModalBottomSheet(
                 context: context,
                 isScrollControlled: true,
                 backgroundColor: Colors.transparent,
                 builder: (context) => OfferBottomSheet(
                   onSendOffer: (newAmount) {
                     ref.read(chatProvider(widget.conversationId).notifier).sendOffer(newAmount);
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