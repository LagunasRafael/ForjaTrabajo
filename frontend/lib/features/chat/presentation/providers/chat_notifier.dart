import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forja_trabajo/features/chat/domain/repositories/chat_repository.dart';
import 'package:forja_trabajo/features/chat/data/models/message_model.dart';
import 'package:forja_trabajo/features/chat/presentation/providers/chat_list_provider.dart';
import 'package:forja_trabajo/features/services/presentation/providers/service_list_provider.dart';
import 'package:forja_trabajo/features/services/presentation/providers/job_management_provider.dart';
import 'package:forja_trabajo/features/chat/presentation/providers/chat_websocket_mixin.dart';
import 'package:forja_trabajo/features/chat/presentation/providers/chat_media_mixin.dart';

class ChatNotifier extends StateNotifier<List<MessageModel>>
    with ChatWebSocketMixin, ChatMediaMixin {
  @override
  final ChatRepository repository;
  @override
  final String conversationId;
  @override
  final String userId;
  @override
  final Ref ref;
  @override
  bool isDisposed = false;
  bool _isLoadingMore = false;
  int _currentLimit = 15;

  ChatNotifier({
    required ChatRepository repository,
    required this.conversationId,
    required this.userId,
    required this.ref,
  }) : repository = repository,
       super([]) {
    if (userId.isNotEmpty && conversationId.isNotEmpty) {
      _initChat();
    }
  }

  bool get isLoadingMore => _isLoadingMore;

  @override
  void dispose() {
    isDisposed = true;
    wsDisconnect();
    super.dispose();
  }

  Future<void> _initChat() async {
    if (conversationId.isEmpty || isDisposed) return;
    
    try {
      print("📦 [Chat] Cargando historial para $conversationId...");
      final history = await repository.getChatHistory(conversationId);
      
      if (!isDisposed) {
        state = history.map((m) => MessageModel.fromEntity(m)).toList();
      }
      
      try {
        await repository.markAsRead(conversationId);
        ref.read(chatListProvider.notifier).markAsReadLocal(conversationId);
      } catch (e) {
        print("⚠️ [Chat] Error al marcar como leído (no crítico): $e");
      }
    } catch (e) {
      print("🚨 [Chat] Error crítico cargando historial: $e");
    }
    
    wsConnect();
  }

  Future<void> sendMessage(String content, String type) async {
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';

    final optimistic = MessageModel(
      id: tempId,
      conversationId: conversationId,
      senderId: userId,
      content: content,
      messageType: type,
      createdAt: DateTime.now().toUtc(),
      status: 'sending',
    );

    state = [optimistic, ...state];
    ref.read(chatListProvider.notifier).loadRealChats();

    if (wsChannel != null) {
      try {
        final message = jsonEncode({
          "content": content,
          "type": type,
          "conversation_id": conversationId
        });
        wsChannel!.sink.add(message);
        print("📤 [Chat] Enviado por WS: $content");

        _markOptimisticSent(tempId, optimistic);
      } catch (e) {
        print("❌ [Chat] Error al enviar WS: $e");
        _sendViaRest(content, type, tempId, optimistic);
      }
    } else {
      _sendViaRest(content, type, tempId, optimistic);
    }
  }

  void _markOptimisticSent(String tempId, MessageModel optimistic) {
    final i = state.indexWhere((m) => m.id == tempId);
    if (i != -1 && mounted) {
      final sent = MessageModel(
        id: tempId,
        conversationId: conversationId,
        senderId: userId,
        content: optimistic.content,
        messageType: optimistic.messageType,
        createdAt: optimistic.createdAt,
        status: 'sent',
      );
      state = [
        for (int j = 0; j < state.length; j++)
          if (j == i) sent else state[j],
      ];
    }
  }

  Future<void> _sendViaRest(String content, String type, String tempId, MessageModel optimistic) async {
    try {
      print("📤 [Chat] Enviando por REST: $content");
      final saved = await repository.sendMessageRest(conversationId, content, type);
      final realId = saved.id;

      final i = state.indexWhere((m) => m.id == tempId);
      if (i != -1 && mounted) {
        final updated = MessageModel(
          id: realId,
          conversationId: conversationId,
          senderId: userId,
          content: content,
          messageType: type,
          createdAt: saved.createdAt,
          status: 'sent',
        );
        state = [
          for (int j = 0; j < state.length; j++)
            if (j == i) updated else state[j],
        ];
        print("✅ [Chat] Mensaje enviado por REST: $realId");
      }
      ref.read(chatListProvider.notifier).loadRealChats();
    } catch (e) {
      print("❌ [Chat] Error enviando por REST: $e");
      final i = state.indexWhere((m) => m.id == tempId);
      if (i != -1 && mounted) {
        final updated = MessageModel(
          id: tempId,
          conversationId: conversationId,
          senderId: userId,
          content: content,
          messageType: type,
          createdAt: optimistic.createdAt,
          status: 'error',
        );
        state = [
          for (int j = 0; j < state.length; j++)
            if (j == i) updated else state[j],
        ];
      }
    }
  }

  Future<void> loadMoreMessages() async {
    if (_isLoadingMore) return;
    _isLoadingMore = true;
    try {
      final moreHistory = await repository.getChatHistory(
        conversationId, 
        skip: state.length,
        limit: _currentLimit
      );
      
      if (moreHistory.isNotEmpty && mounted) {
        final newMessages = moreHistory.map((m) => MessageModel.fromEntity(m)).toList();
        state = [...state, ...newMessages];
      }
    } catch (e) {
      print("🚨 Error cargando más: $e");
    } finally {
      _isLoadingMore = false;
    }
  }

  Future<void> openDispute(String reason) async {
    try {
      final systemMessage = await repository.openDispute(conversationId, reason);
      final model = MessageModel.fromEntity(systemMessage);
      if (!state.any((m) => m.id == model.id)) {
        if (mounted) state = [model, ...state];
      }
      ref.read(chatListProvider.notifier).loadRealChats();
      ref.invalidate(myRequestsProvider);
      ref.invalidate(workerJobsProvider);
      ref.invalidate(serviceListProvider);
    } catch (e) {
      print("Error abriendo disputa: $e");
      rethrow;
    }
  }

  Future<void> sendOffer(double amount) async {
    try {
      final response = await repository.sendOffer(conversationId, amount);
      {
        final newOffer = MessageModel.fromJson(response);
        if (!state.any((m) => m.id == newOffer.id)) {
          state = [newOffer, ...state];
        }
      }
      ref.read(chatListProvider.notifier).loadRealChats();
    } catch (e) {
      print("🚨 Error enviando oferta: $e");
      rethrow;
    }
  }

  Future<void> respondOffer(String messageId, String action) async {
    try {
      await repository.respondOffer(messageId, action);
      
      if (mounted) {
        state = [
          for (final m in state)
            if (m.id == messageId)
              MessageModel(
                id: m.id,
                conversationId: m.conversationId,
                senderId: m.senderId,
                content: m.content,
                messageType: m.messageType,
                createdAt: m.createdAt,
                status: action == 'accept' ? 'accepted' : 'rejected',
              )
            else
              m
        ];
      }
      
      ref.read(chatListProvider.notifier).loadRealChats();
    } catch (e) {
      print("🚨 Error respondiendo oferta: $e");
      rethrow;
    }
  }

  Future<void> sendLocation(String locationJson) async {
    await sendMessage(locationJson, "location");
  }

  void resendMessage(String messageId) {
    final idx = state.indexWhere((m) => m.id == messageId);
    if (idx == -1) return;
    final msg = state[idx];
    print("🔄 Reintentando mensaje: $messageId -> ${msg.content}");
    state = [
      for (int i = 0; i < state.length; i++)
        if (i != idx) state[i] else ...[
        ],
    ];
    sendMessage(msg.content, msg.messageType);
  }
}
