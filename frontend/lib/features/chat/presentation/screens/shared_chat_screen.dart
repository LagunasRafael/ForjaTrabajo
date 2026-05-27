import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forja_trabajo/features/chat/domain/entities/message_entity.dart';
import 'package:forja_trabajo/features/chat/presentation/widgets/negotiation_card.dart';
import 'package:forja_trabajo/features/auth/presentation/providers/auth_provider.dart';
import 'package:forja_trabajo/features/chat/presentation/providers/chat_provider.dart';
import 'package:forja_trabajo/features/chat/presentation/providers/chat_typing_provider.dart';
import 'package:forja_trabajo/features/chat/presentation/providers/chat_list_provider.dart';
import 'package:forja_trabajo/features/chat/presentation/widgets/chat_bubble.dart';
import 'package:forja_trabajo/features/chat/presentation/widgets/chat_app_bar.dart';
import 'package:forja_trabajo/features/chat/presentation/widgets/chat_input_area.dart';
import 'package:forja_trabajo/core/network/notification_service.dart';
import 'package:forja_trabajo/features/chat/presentation/widgets/chat_dispute_dialog.dart';
import 'package:forja_trabajo/features/chat/presentation/widgets/chat_closed_banner.dart';
import 'package:forja_trabajo/features/chat/presentation/widgets/chat_typing_indicator.dart';
import 'package:forja_trabajo/features/chat/presentation/widgets/chat_negotiation_banner.dart';
import 'package:forja_trabajo/features/services/presentation/screens/shared/service_detail_screen.dart';
import 'package:forja_trabajo/features/services/domain/entities/service_entity.dart';
import 'package:forja_trabajo/features/chat/presentation/widgets/chat_day_divider.dart';
import 'package:forja_trabajo/features/chat/presentation/widgets/chat_empty_state.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

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

  bool _isSameDay(DateTime a, DateTime b) {
    final da = a.toLocal();
    final db = b.toLocal();
    return da.year == db.year && da.month == db.month && da.day == db.day;
  }

  List<dynamic> _buildChatItems(List<MessageEntity> messages) {
    final items = <dynamic>[];
    DateTime? lastDate;
    for (final msg in messages) {
      if (lastDate == null || !_isSameDay(lastDate, msg.createdAt)) {
        items.add(ChatDayDivider.fromDateTime(msg.createdAt));
      }
      items.add(msg);
      lastDate = msg.createdAt;
    }
    return items;
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
    final theme = Theme.of(context);
    ref.listen<AsyncValue<RemoteMessage>>(notificationEventProvider, (previous, next) {
      next.whenData((message) {
        final type = message.data['type'] ?? '';
        if (type == 'job_completed' || type == 'job_cancelled' || type == 'dispute_resolved') {
          ref.invalidate(chatProvider(widget.conversationId));
        }
      });
    });

    final messages = ref.watch(chatProvider(widget.conversationId));
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

    final isInitialLoading = authState.status == 'loading' || (messages.isEmpty && !chatNotifier.isConnected);

    final lastOffer = _getLastOffer(messages);
    final isOfferAccepted = messages.any((m) => m.messageType == 'offer' &&
        (m.status.toLowerCase() == 'accept' || m.status.toLowerCase() == 'accepted'));

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

    final isClosed = thisChat?.status.toUpperCase() == 'CERRADO' || thisChat?.status.toUpperCase() == 'CLOSED';
    final closedReason = thisChat?.closedReason;

    final sStatus = (thisChat?.serviceStatus ?? 'open').toLowerCase();
    final isMatched = sStatus != 'open' && sStatus != 'jobstatus.open';

    final canSendOffer = !isClosed && !isOfferAccepted && !isMatched;

    final hasActiveOffer = lastOffer != null &&
        lastOffer.status.toLowerCase() == 'pending' &&
        canSendOffer;
    final subtitlePrefix = isClosed
        ? "Chat finalizado"
        : (thisChat?.status.toUpperCase() == 'EN DISPUTA')
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
        onOpenDispute: () => showDisputeDialog(context, ref, widget.conversationId),
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
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    theme.brightness == Brightness.dark
                        ? const Color(0xFF1E1B4B).withValues(alpha: 0.3)
                        : const Color(0xFFE0E7FF),
                    theme.brightness == Brightness.dark
                        ? const Color(0xFF1E1B4B).withValues(alpha: 0.15)
                        : const Color(0xFFC7D2FE),
                    theme.colorScheme.surface,
                  ],
                ),
              ),
              child: isInitialLoading
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                  ),
                )
              : messages.isEmpty
                ? const ChatEmptyState()
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
                      cacheExtent: 1000,
                      itemCount: _buildChatItems(messages).length + 1,
                      itemBuilder: (context, index) {
                        final displayItems = _buildChatItems(messages);
                        if (index == displayItems.length) {
                          final notifier = ref.read(chatProvider(widget.conversationId).notifier);
                          if (notifier.isLoadingMore) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 20),
                              child: Center(
                                child: SizedBox(
                                  width: 24, height: 24,
                                  child: CircularProgressIndicator(
                                    color: Color(0xFF4F46E5),
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        }

                        final item = displayItems[index];
                        if (item is ChatDayDivider) {
                          return item;
                        }

                        final m = item as MessageEntity;
                        final isMyMessage = m.senderId == myId;

                        String displayTime = m.displayTime;

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
            ),

            if (isClient && hasActiveOffer)
            ChatNegotiationBanner(
              amount: lastOffer.content.toString(),
              conversationId: widget.conversationId,
            ),

          if (isOtherUserTyping) ChatTypingIndicator(otherUserName: widget.otherUserName),

          if (isClosed)
            ChatClosedBanner(closedReason: closedReason),

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
}
