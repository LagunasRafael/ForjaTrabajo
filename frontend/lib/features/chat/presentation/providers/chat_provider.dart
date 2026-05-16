import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forja_trabajo/features/auth/presentation/providers/auth_provider.dart';
import 'package:forja_trabajo/features/chat/data/datasources/chat_remote_datasource.dart';
import 'package:forja_trabajo/features/chat/data/repositories/chat_repository_impl.dart';
import 'package:forja_trabajo/features/chat/data/models/message_model.dart';
import 'package:forja_trabajo/features/chat/domain/repositories/chat_repository.dart';
import 'package:forja_trabajo/features/chat/presentation/providers/chat_list_provider.dart'; // 👈 Agregado
import 'package:web_socket_channel/web_socket_channel.dart';

// --- PROVIDERS DE INFRAESTRUCTURA ---

final chatDatasourceProvider = Provider<ChatRemoteDataSource>((ref) {
  return ChatRemoteDataSource();
});

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  final dataSource = ref.watch(chatDatasourceProvider);
  return ChatRepositoryImpl(remoteDataSource: dataSource);
});

// --- PROVIDERS DE ESTADO ---

/// Provider para detectar si el otro usuario está escribiendo
final chatTypingProvider = StateProvider.family<bool, String>((ref, conversationId) {
  return false;
});

/// Provider principal del chat (Lista de mensajes)
final chatProvider = StateNotifierProvider.family<ChatNotifier, List<MessageModel>, String>((ref, conversationId) {
  final repository = ref.watch(chatRepositoryProvider);
  final auth = ref.watch(authProvider);
  final userId = auth.user?.id ?? '';
  
  return ChatNotifier(
    repository: repository,
    conversationId: conversationId,
    userId: userId,
    ref: ref,
  );
});

class ChatNotifier extends StateNotifier<List<MessageModel>> {
  final ChatRepository _repository;
  final String conversationId;
  final String userId;
  final Ref ref;
  WebSocketChannel? _channel;
  bool _isReconnecting = false;
  bool _isLoadingMore = false;
  
  int _currentLimit = 15;

  ChatNotifier({
    required ChatRepository repository,
    required this.conversationId,
    required this.userId,
    required this.ref,
  }) : _repository = repository,
       super([]) {
    _initChat();
  }

  bool get isLoadingMore => _isLoadingMore;

  Future<void> _initChat() async {
    if (conversationId.isEmpty) return;
    try {
      // 1. Cargar historial
      final history = await _repository.getChatHistory(conversationId);
      if (mounted) {
        state = history.map((m) => MessageModel.fromEntity(m)).toList();
      }
      
      // 2. Marcar como leído en el servidor y localmente
      _repository.markAsRead(conversationId);
      ref.read(chatListProvider.notifier).markAsReadLocal(conversationId);
      
      // 3. Conectar WebSocket
      _connect();
    } catch (e) {
      print("🚨 Error cargando historial: $e");
      _connect(); 
    }
  }

  void _connect() {
    if (_isReconnecting || userId.isEmpty || conversationId.isEmpty) return;

    // 💡 URL Dinámica para WebSocket
    final String wsBaseUrl;
    if (kDebugMode) {
      wsBaseUrl = Platform.isAndroid ? 'ws://10.0.2.2:8000' : 'ws://localhost:8000';
    } else {
      // Usar la misma URL que ApiClient pero con protocolo wss://
      wsBaseUrl = 'wss://forja-api-rw0r.onrender.com';
    }

    final wsUrl = "$wsBaseUrl/services/chat/ws/$conversationId/$userId";
    print("🔌 CONNECTING WS: $wsUrl");
    
    try {
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

      _channel!.stream.listen(
        (message) => _handleIncomingMessage(message),
        onError: (error) => _reconnect(),
        onDone: () => _reconnect(),
        cancelOnError: false,
      );
    } catch (e) {
      _reconnect();
    }
  }

  void _handleIncomingMessage(dynamic message) {
    if (!mounted) return;
    
    try {
      final decoded = jsonDecode(message);
      
      // 1. Filtrar por conversationId si viene en el payload
      final incomingConvoId = decoded['conversation_id']?.toString() ?? '';
      if (incomingConvoId.isNotEmpty && incomingConvoId != conversationId) {
        print("⏭️ Ignorando mensaje de otra conversación: $incomingConvoId");
        return;
      }

      if (decoded is Map && decoded['type'] == 'typing') {
        final senderId = decoded['sender_id'];
        if (senderId != userId) {
          ref.read(chatTypingProvider(conversationId).notifier).state = decoded['is_typing'] ?? false;
        }
        return;
      }

      final newMessage = MessageModel.fromJson(decoded);

      // 2. Evitar duplicados (por ID)
      if (state.any((m) => m.id == newMessage.id)) {
        print("⏭️ Ignorando mensaje duplicado: ${newMessage.id}");
        return;
      }

      state = [newMessage, ...state];
      
      // 3. Si llega un mensaje mientras estamos dentro, refrescar la lista global
      ref.read(chatListProvider.notifier).loadRealChats();
      _repository.markAsRead(conversationId);
    } catch (e) {
      print("🚨 Error procesando mensaje WS: $e");
    }
  }

  void _reconnect() {
    if (!mounted || _isReconnecting) return;
    _isReconnecting = true;
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _isReconnecting = false;
        _connect();
      }
    });
  }

  // --- ACCIONES DE CHAT ---

  Future<void> sendMessage(String content, String type) async {
    if (_channel == null) return;
    final message = jsonEncode({
      "content": content, 
      "type": type,
      "conversation_id": conversationId
    });
    _channel!.sink.add(message);
    // Refrescar lista para ver nuestro mensaje enviado como último mensaje
    ref.read(chatListProvider.notifier).loadRealChats();
  }

  void sendTyping(bool isTyping) {
    if (_channel == null) return;
    final message = jsonEncode({"type": "typing", "is_typing": isTyping});
    _channel!.sink.add(message);
  }

  Future<void> loadMoreMessages() async {
    if (_isLoadingMore) return;
    _isLoadingMore = true;
    try {
      final moreHistory = await _repository.getChatHistory(
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
      await _repository.openDispute(conversationId, reason);
    } catch (e) {
      print("🚨 Error abriendo disputa: $e");
      rethrow;
    }
  }

  Future<void> sendOffer(double amount) async {
    try {
      await _repository.sendOffer(conversationId, amount);
      ref.read(chatListProvider.notifier).loadRealChats();
    } catch (e) {
      print("🚨 Error enviando oferta: $e");
      rethrow;
    }
  }

  Future<void> respondOffer(String messageId, String action) async {
    try {
      await _repository.respondOffer(messageId, action);
      ref.read(chatListProvider.notifier).loadRealChats();
    } catch (e) {
      print("🚨 Error respondiendo oferta: $e");
      rethrow;
    }
  }

  Future<void> sendMediaBatch(List<String> paths, String? text) async {
    if (paths.isEmpty) return;
    try {
      List<String> uploadedUrls = [];
      for (var path in paths) {
        final url = await _repository.uploadChatMedia(conversationId, path);
        if (url != null) uploadedUrls.add(url);
      }
      
      if (uploadedUrls.isNotEmpty) {
        final content = uploadedUrls.join(',');
        await sendMessage(content, uploadedUrls.length > 1 ? 'gallery' : 'image');
        if (text != null && text.isNotEmpty) {
          await sendMessage(text, 'text');
        }
      }
    } catch (e) {
      print("🚨 Error subiendo archivos: $e");
    }
  }

  Future<void> sendLocation() async {
    // Implementación simplificada: asume que la UI ya obtuvo la ubicación
    // o que se maneja un placeholder. 
    print("📍 Compartiendo ubicación...");
    await sendMessage("Ubicación compartida", "location");
  }

  void resendMessage(String messageId) {
    print("🔄 Reintentando mensaje: $messageId");
  }

  @override
  void dispose() {
    _channel?.sink.close();
    super.dispose();
  }
}
