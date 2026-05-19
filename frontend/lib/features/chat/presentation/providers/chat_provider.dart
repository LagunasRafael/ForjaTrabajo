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
import 'package:forja_trabajo/features/chat/presentation/providers/chat_list_provider.dart';
import 'package:forja_trabajo/core/network/api_client.dart';
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
  Timer? _pollingTimer;
  
  int _currentLimit = 15;
  bool _isDisposed = false;

  ChatNotifier({
    required ChatRepository repository,
    required this.conversationId,
    required this.userId,
    required this.ref,
  }) : _repository = repository,
       super([]) {
    if (userId.isNotEmpty && conversationId.isNotEmpty) {
      _initChat();
    }
  }

  bool get isLoadingMore => _isLoadingMore;
  bool get isConnected => _channel != null && !_isReconnecting;

  @override
  void dispose() {
    _isDisposed = true;
    _pollingTimer?.cancel();
    _channel?.sink.close();
    super.dispose();
  }

  Future<void> _initChat() async {
    if (conversationId.isEmpty || _isDisposed) return;
    
    try {
      print("📦 [Chat] Cargando historial para $conversationId...");
      // 1. Cargar historial
      final history = await _repository.getChatHistory(conversationId);
      
      if (!_isDisposed) {
        state = history.map((m) => MessageModel.fromEntity(m)).toList();
      }
      
      // 2. Marcar como leído
      try {
        await _repository.markAsRead(conversationId);
        ref.read(chatListProvider.notifier).markAsReadLocal(conversationId);
      } catch (e) {
        print("⚠️ [Chat] Error al marcar como leído (no crítico): $e");
      }
      
      // 3. Conectar WebSocket
      _connect();

      // 4. Polling de seguridad cada 6 segundos para no perder mensajes
      _pollingTimer?.cancel();
      _pollingTimer = Timer.periodic(const Duration(seconds: 6), (_) async {
        if (_isDisposed || !mounted) return;
        // Solo hacer polling si el WS no está conectado
        if (_channel == null || _isReconnecting) {
          await _pollNewMessages();
        }
      });
    } catch (e) {
      print("🚨 [Chat] Error crítico cargando historial: $e");
      _connect(); 
    }
  }

  /// Pide al servidor los mensajes más recientes y los fusiona sin duplicados
  Future<void> _pollNewMessages() async {
    try {
      final history = await _repository.getChatHistory(conversationId, skip: 0, limit: _currentLimit);
      if (!mounted || _isDisposed) return;
      final fresh = history.map((m) => MessageModel.fromEntity(m)).toList();
      // Solo agregar mensajes que no tengamos ya (evitar regresar temp messages)
      final existingIds = state.where((m) => !m.id.startsWith('temp_')).map((m) => m.id).toSet();
      final newOnes = fresh.where((m) => !existingIds.contains(m.id)).toList();
      if (newOnes.isNotEmpty) {
        print("🔄 [Poll] ${newOnes.length} mensajes nuevos recuperados");
        state = [...newOnes, ...state];
      }
    } catch (e) {
      print("⚠️ [Poll] Error en polling: $e");
    }
  }

  void _connect() {
    if (_isDisposed || _isReconnecting || userId.isEmpty || conversationId.isEmpty) return;

    final apiBase = ApiClient.baseUrl;
    final wsBaseUrl = apiBase
        .replaceFirst('https://', 'wss://')
        .replaceFirst('http://', 'ws://');

    final wsUrl = "$wsBaseUrl/services/chat/ws/$conversationId/$userId";
    print("🔌 [WS] Conectando a: $wsUrl");
    
    try {
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

      _channel!.stream.listen(
        (message) {
          print("📥 [WS] Raw recibido: $message");
          _handleIncomingMessage(message);
        },
        onError: (error) {
          print("❌ [WS] Error de conexión: $error");
          _reconnect();
        },
        onDone: () {
          print("🔌 [WS] Conexión cerrada por el servidor");
          _reconnect();
        },
        cancelOnError: false,
      );
    } catch (e) {
      print("🚨 [WS] Excepción al conectar: $e");
      _reconnect();
    }
  }


  void _handleIncomingMessage(dynamic message) {
    if (!mounted) return;

    try {
      final decoded = jsonDecode(message);

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
      print("📥 [WS] Mensaje procesado: id=${newMessage.id} sender=${newMessage.senderId} tipo=${newMessage.messageType}");

      final existingIdx = state.indexWhere((m) => m.id == newMessage.id);
      if (existingIdx != -1) {
        print("🔄 [WS] Actualizando mensaje existente: ${newMessage.id}");
        state = [
          for (int i = 0; i < state.length; i++)
            if (i == existingIdx) newMessage else state[i],
        ];
        ref.read(chatListProvider.notifier).loadRealChats();
        return;
      }

      // Mensajes de sistema (disputas, resoluciones del admin) siempre se agregan directo
      if (newMessage.messageType == 'system') {
        state = [newMessage, ...state];
        ref.read(chatListProvider.notifier).loadRealChats();
        _repository.markAsRead(conversationId);
        return;
      }

      if (newMessage.senderId == userId) {
        final tempIdx = state.indexWhere((m) => m.id.startsWith('temp_') && m.content == newMessage.content);
        if (tempIdx != -1) {
          print("🔄 [WS] Reemplazando temp id=${state[tempIdx].id} con real id=${newMessage.id}");
          state = [
            for (int i = 0; i < state.length; i++)
              if (i == tempIdx) newMessage else state[i],
          ];
        } else {
          print("📥 [WS] Mensaje propio (sin temp), agregando: ${newMessage.id}");
          state = [newMessage, ...state];
        }
      } else {
        state = [newMessage, ...state];
      }

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

    if (_channel != null) {
      try {
        final message = jsonEncode({
          "content": content,
          "type": type,
          "conversation_id": conversationId
        });
        _channel!.sink.add(message);
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
      final saved = await _repository.sendMessageRest(conversationId, content, type);
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
      final systemMessage = await _repository.openDispute(conversationId, reason);
      // Insertar el mensaje de sistema INMEDIATAMENTE en el estado
      final model = MessageModel.fromEntity(systemMessage);
      // Evitar duplicados si el WS ya lo trajo
      if (!state.any((m) => m.id == model.id)) {
        if (mounted) state = [model, ...state];
      }
      ref.read(chatListProvider.notifier).loadRealChats();
    } catch (e) {
      print("Error abriendo disputa: $e");
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
      
      // Actualizar estado local inmediatamente
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

  Future<void> sendMediaBatch(List<String> paths, String? caption) async {
    if (paths.isEmpty) return;

    // Separar audios de imágenes/videos por extensión
    final audioPaths = paths.where((p) {
      final ext = p.split('.').last.toLowerCase();
      return ['m4a', 'mp3', 'ogg', 'wav', 'aac', 'opus'].contains(ext);
    }).toList();

    final imagePaths = paths.where((p) {
      final ext = p.split('.').last.toLowerCase();
      return !['m4a', 'mp3', 'ogg', 'wav', 'aac', 'opus'].contains(ext);
    }).toList();

    // ──────────────────────────────────────────────────────────────────────────
    // 1. OPTIMISTA: insertar burbuja(s) de IMÁGENES de inmediato (local paths)
    // ──────────────────────────────────────────────────────────────────────────
    String? imageTempId;
    if (imagePaths.isNotEmpty) {
      imageTempId = 'temp_media_${DateTime.now().millisecondsSinceEpoch}';
      final localContent = imagePaths.join(',');
      final optimistic = MessageModel(
        id: imageTempId,
        conversationId: conversationId,
        senderId: userId,
        content: localContent,
        messageType: imagePaths.length > 1 ? 'gallery' : 'image',
        createdAt: DateTime.now().toUtc(),
        status: 'sending',
      );
      state = [optimistic, ...state];
      ref.read(chatListProvider.notifier).loadRealChats();
    }

    // ──────────────────────────────────────────────────────────────────────────
    // 2. OPTIMISTA: insertar burbuja(s) de AUDIO de inmediato (local paths)
    // ──────────────────────────────────────────────────────────────────────────
    final audioTempIds = <String, String>{}; // tempId -> localPath
    for (final path in audioPaths) {
      final tempId = 'temp_audio_${DateTime.now().millisecondsSinceEpoch}_${path.hashCode}';
      final optimistic = MessageModel(
        id: tempId,
        conversationId: conversationId,
        senderId: userId,
        content: path,
        messageType: 'audio',
        createdAt: DateTime.now().toUtc(),
        status: 'sending',
      );
      state = [optimistic, ...state];
      audioTempIds[tempId] = path;
    }

    // ──────────────────────────────────────────────────────────────────────────
    // 3. SUBIDA REAL: imágenes
    // ──────────────────────────────────────────────────────────────────────────
    if (imagePaths.isNotEmpty && imageTempId != null) {
      try {
        List<String> uploadedUrls = [];
        for (final path in imagePaths) {
          final url = await _repository.uploadChatMedia(conversationId, path);
          if (url != null) uploadedUrls.add(url);
        }

        if (uploadedUrls.isNotEmpty) {
          // Enviar al servidor y obtener ID real
          final content = uploadedUrls.join(',');
          final type = uploadedUrls.length > 1 ? 'gallery' : 'image';
          
          try {
            final saved = await _repository.sendMessageRest(conversationId, content, type);
            // Reemplazar el optimista con el real (URL de S3)
            final idx = state.indexWhere((m) => m.id == imageTempId);
            if (idx != -1 && mounted) {
              state = [
                for (int i = 0; i < state.length; i++)
                  if (i == idx)
                    MessageModel(
                      id: saved.id,
                      conversationId: conversationId,
                      senderId: userId,
                      content: content,
                      messageType: type,
                      createdAt: saved.createdAt,
                      status: 'sent',
                    )
                  else
                    state[i],
              ];
            }
          } catch (e) {
            _setMediaError(imageTempId!);
          }
        } else {
          _setMediaError(imageTempId!);
        }
      } catch (e) {
        print("🚨 Error subiendo imágenes: $e");
        _setMediaError(imageTempId!);
      }
    }

    // ──────────────────────────────────────────────────────────────────────────
    // 4. SUBIDA REAL: audios (uno por uno)
    // ──────────────────────────────────────────────────────────────────────────
    for (final entry in audioTempIds.entries) {
      final tempId = entry.key;
      final path = entry.value;
      try {
        final url = await _repository.uploadChatMedia(conversationId, path);
        if (url != null) {
          try {
            final saved = await _repository.sendMessageRest(conversationId, url, 'audio');
            final idx = state.indexWhere((m) => m.id == tempId);
            if (idx != -1 && mounted) {
              state = [
                for (int i = 0; i < state.length; i++)
                  if (i == idx)
                    MessageModel(
                      id: saved.id,
                      conversationId: conversationId,
                      senderId: userId,
                      content: url,
                      messageType: 'audio',
                      createdAt: saved.createdAt,
                      status: 'sent',
                    )
                  else
                    state[i],
              ];
            }
          } catch (e) {
            _setMediaError(tempId);
          }
        } else {
          _setMediaError(tempId);
        }
      } catch (e) {
        print("🚨 Error subiendo audio: $e");
        _setMediaError(tempId);
      }
    }

    // ──────────────────────────────────────────────────────────────────────────
    // 5. Caption (texto extra si se añadió)
    // ──────────────────────────────────────────────────────────────────────────
    if (caption != null && caption.isNotEmpty) {
      await sendMessage(caption, 'text');
    }

    ref.read(chatListProvider.notifier).loadRealChats();
  }

  /// Marca un mensaje optimista como 'error' para que el usuario pueda reintentar
  void _setMediaError(String tempId) {
    final idx = state.indexWhere((m) => m.id == tempId);
    if (idx != -1 && mounted) {
      final old = state[idx];
      state = [
        for (int i = 0; i < state.length; i++)
          if (i == idx)
            MessageModel(
              id: old.id,
              conversationId: old.conversationId,
              senderId: old.senderId,
              content: old.content,
              messageType: old.messageType,
              createdAt: old.createdAt,
              status: 'error',
            )
          else
            state[i],
      ];
    }
  }

  Future<void> sendLocation() async {
    // Implementación simplificada: asume que la UI ya obtuvo la ubicación
    // o que se maneja un placeholder. 
    print("📍 Compartiendo ubicación...");
    await sendMessage("Ubicación compartida", "location");
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
