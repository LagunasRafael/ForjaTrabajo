import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:forja_trabajo/core/network/api_client.dart';
import 'package:forja_trabajo/features/auth/presentation/providers/auth_provider.dart';
import 'package:forja_trabajo/features/chat/data/datasources/chat_remote_datasource.dart';
import 'package:forja_trabajo/features/chat/data/repositories/chat_repository_impl.dart';
import 'package:forja_trabajo/features/chat/domain/usecases/get_chat_history_usecase.dart';
import 'package:forja_trabajo/features/chat/domain/repositories/chat_repository.dart';
import 'package:forja_trabajo/features/chat/domain/usecases/send_offer_usecase.dart';
import 'package:forja_trabajo/features/chat/domain/usecases/respond_offer_usecase.dart';
import 'package:forja_trabajo/features/chat/domain/entities/message_entity.dart';
import 'package:forja_trabajo/features/chat/data/models/message_model.dart';


// --- 1. DATASOURCE & REPOSITORY ---
final chatDatasourceProvider = Provider((ref) => ChatRemoteDataSource());

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  final dataSource = ref.watch(chatDatasourceProvider);
  return ChatRepositoryImpl(remoteDataSource: dataSource);
});

// --- 2. USE CASES ---
final getChatHistoryUseCaseProvider = Provider((ref) {
  final repository = ref.watch(chatRepositoryProvider);
  return GetChatHistoryUseCase(repository);
});


final sendOfferUseCaseProvider = Provider((ref) {
  final repository = ref.watch(chatRepositoryProvider);
  return SendOfferUseCase(repository);
});

final respondOfferUseCaseProvider = Provider((ref) {
  final repository = ref.watch(chatRepositoryProvider);
  return RespondOfferUseCase(repository);
});

// --- 3. PROVIDER DE TYPING ---
final chatTypingProvider = StateProvider.family<bool, String>((ref, conversationId) => false);

// --- 4. EL PROVIDER PRINCIPAL DEL CHAT ---
final chatProvider = StateNotifierProvider.family<ChatNotifier, List<MessageEntity>, String>((ref, conversationId) {
  final user = ref.watch(authProvider).user;
  
  final getHistory = ref.watch(getChatHistoryUseCaseProvider);
  final sendOffer = ref.watch(sendOfferUseCaseProvider); 
  final respondOffer = ref.watch(respondOfferUseCaseProvider); 
  
  return ChatNotifier(
    ref: ref,
    conversationId: conversationId, 
    userId: user?.id ?? '', 
    getHistoryUseCase: getHistory,
    sendOfferUseCase: sendOffer, 
    respondOfferUseCase: respondOffer, 
  );
});

// --- 5. EL NOTIFIER (CEREBRO PAGINADO) ---
class ChatNotifier extends StateNotifier<List<MessageEntity>> {
  final Ref ref;
  final String conversationId;
  final String userId;
  final GetChatHistoryUseCase getHistoryUseCase;
  final SendOfferUseCase sendOfferUseCase;
  final RespondOfferUseCase respondOfferUseCase;
  
  WebSocketChannel? _channel;

  // 🧠 Variables de Paginación
  int _currentSkip = 0;
  int _limit = 15; // 👈 15 para texto, se adapta a 10 si hay media
  bool _hasMore = true;
  bool isLoadingMore = false;
  Timer? _typingTimer;

  ChatNotifier({
    required this.ref,
    required this.conversationId, 
    required this.userId,
    required this.getHistoryUseCase,
    required this.sendOfferUseCase,
    required this.respondOfferUseCase,
  }) : super([]) {
    _initChat();
  }

  Future<void> _initChat() async {
    try {
      _currentSkip = 0;
      _hasMore = true;
      
      final history = await getHistoryUseCase(conversationId, skip: _currentSkip, limit: _limit);
      
      // Backend ya devuelve DESC (más reciente primero) = orden correcto para reverse ListView
      state = history;

      if (history.length < _limit) _hasMore = false;
      _currentSkip += history.length;
      
      // 🧠 Adaptar límite según contenido: si hay media, cargar menos
      _adaptLimit(history);

      _connect();
    } catch (e) {
      print("🚨 Error cargando historial: $e");
      _connect(); 
    }
  }

  /// Adapta el límite de paginación según si hay media pesada en el lote
  void _adaptLimit(List<MessageEntity> batch) {
    final hasMedia = batch.any((m) => 
      m.messageType == 'image' || m.messageType == 'video' || m.messageType == 'gallery'
    );
    _limit = hasMedia ? 10 : 15;
  }

  // 🚀 LA MAGIA DE CARGAR MÁS
  Future<void> loadMoreMessages() async {
    if (isLoadingMore || !_hasMore || _disposed) return;
    
    isLoadingMore = true;
    state = [...state]; // Forzar rebuild para mostrar loading spinner si existe

    try {
      final olderMessages = await getHistoryUseCase(conversationId, skip: _currentSkip, limit: _limit);
      
      if (olderMessages.isEmpty) {
        _hasMore = false;
      } else {
        // Backend ya devuelve DESC, colocamos al final (más antiguos)
        state = [...state, ...olderMessages]; 
        _currentSkip += olderMessages.length;
        _hasMore = olderMessages.length == _limit;
        _adaptLimit(olderMessages);
      }
    } catch (e) {
      print("🚨 Error cargando más mensajes: $e");
    } finally {
      isLoadingMore = false;
      state = [...state]; 
    }
  }

  int _reconnectAttempts = 0;
  bool _disposed = false;

  void _connect() {
    if (_disposed) return;

    final wsUrl = ApiClient.baseUrl.replaceFirst('http', 'ws') + 
                 '/services/chat/ws/$conversationId/$userId';
    
    print("🔌 WS CONNECTING to: $wsUrl");

    try {
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
    } catch (e) {
      print("🚨 WS CONNECTION FAILED: $e");
      _scheduleReconnect();
      return;
    }

    _channel!.stream.listen(
      (message) {
        try {
          final decoded = jsonDecode(message);
          print("📥 WS RECEIVED in $conversationId: $decoded");

          // Ignorar mensajes de error del servidor
          if (decoded is Map && decoded.containsKey('error')) {
            print("🚨 WS SERVER ERROR: ${decoded['error']}");
            return;
          }

          // 🟢 Detectar typing events
          if (decoded is Map && decoded['type'] == 'typing') {
            final isTyping = decoded['is_typing'] == true;
            ref.read(chatTypingProvider(conversationId).notifier).state = isTyping;

            // Auto-apagar typing después de 5s por seguridad (si se desconecta)
            _typingTimer?.cancel();
            if (isTyping) {
              _typingTimer = Timer(const Duration(seconds: 5), () {
                if (!_disposed) {
                  ref.read(chatTypingProvider(conversationId).notifier).state = false;
                }
              });
            }
            return;
          }

          final nuevoMensaje = MessageModel.fromJson(decoded);
          
          final myId = ref.read(authProvider).user?.id ?? '';
          List<MessageEntity> updatedList = [...state];
          
          if (nuevoMensaje.senderId == myId) {
            final pendingIndex = updatedList.lastIndexWhere(
              (m) => m.status == 'pending' && m.messageType == nuevoMensaje.messageType && m.senderId == myId
            );
            if (pendingIndex != -1) {
              updatedList[pendingIndex] = nuevoMensaje; // 🔥 REEMPLAZO EN SITIO (Mantiene el orden visual original)
            } else {
              updatedList.insert(0, nuevoMensaje);
            }
          } else {
            updatedList.insert(0, nuevoMensaje);
          }
          
          state = updatedList;
          _currentSkip += 1;
          _reconnectAttempts = 0;
        } catch (e) {
          print("🚨 Error decodificando WebSocket: $e");
        }
      },
      onError: (error) {
        print("🚨 WS STREAM ERROR: $error");
        _scheduleReconnect();
      },
      onDone: () {
        print("⚠️ WS STREAM CLOSED (convo=$conversationId)");
        _scheduleReconnect();
      },
    );

    print("✅ WS LISTENER ATTACHED for convo=$conversationId");
  }

  void _scheduleReconnect() {
    if (_disposed) return;

    _channel?.sink.close();
    _channel = null;

    _reconnectAttempts++;
    // Exponential backoff: 1s, 2s, 4s, 8s, ... max 30s
    final delay = Duration(seconds: (_reconnectAttempts * 2).clamp(1, 30));
    print("🔄 WS RECONNECTING in ${delay.inSeconds}s (attempt #$_reconnectAttempts)");

    Future.delayed(delay, () {
      if (!_disposed) {
        _connect();
      }
    });
  }

  void sendMessage(String content, String type) {
    if (_channel == null) {
      print("🚨 WS SEND FAILED: No connection (convo=$conversationId)");
      return;
    }
    
    // Feedback visual inmediato
    final tempId = "temp_${DateTime.now().millisecondsSinceEpoch}";
    final myId = ref.read(authProvider).user?.id ?? '';
    final tempMsg = MessageModel(
      id: tempId,
      senderId: myId,
      content: content,
      messageType: type,
      createdAt: DateTime.now().toUtc(),
      status: 'pending',
    );
    
    List<MessageEntity> updatedList = [tempMsg, ...state];
    state = updatedList;

    final message = jsonEncode({"content": content, "type": type});
    _channel!.sink.add(message);
  }

  void sendTyping(bool isTyping) {
    if (_channel == null) return;
    final message = jsonEncode({"type": "typing", "is_typing": isTyping});
    _channel!.sink.add(message);
  }

  Future<void> sendMediaBatch(List<String> filePaths, String? caption) async {
    final tempId = "temp_${DateTime.now().millisecondsSinceEpoch}";
    final myId = ref.read(authProvider).user?.id ?? '';

    final contentPaths = filePaths.join(',');
    
    String msgType = 'gallery';
    if (filePaths.length == 1) {
       final ext = filePaths.first.toLowerCase();
       if (ext.endsWith('.mp4') || ext.endsWith('.mov') || ext.endsWith('.mkv')) {
          msgType = 'video';
       } else if (ext.endsWith('.m4a') || ext.endsWith('.mp3') || ext.endsWith('.wav')) {
          msgType = 'audio';
       } else {
          msgType = 'image';
       }
    }

    final tempMsg = MessageModel(
      id: tempId,
      senderId: myId,
      content: contentPaths, 
      messageType: msgType,
      createdAt: DateTime.now().toUtc(),
      status: 'pending',
    );
    
    // 🟢 INSERTAR AL PRINCIPIO
    List<MessageEntity> updatedList = [tempMsg, ...state];
    state = updatedList;
    
    if (caption != null && caption.isNotEmpty) {
       sendMessage(caption, "text");
    }

    try {
      final repository = ref.read(chatRepositoryProvider);
      List<String> uploadedUrls = [];
      
      for (final path in filePaths) {
         final url = await repository.uploadChatMedia(conversationId, path);
         if (url != null) {
            uploadedUrls.add(url);
         } else {
            throw Exception("Fallo la subida de un elemento");
         }
      }
      
      final finalContent = uploadedUrls.join(',');
      
      if (_channel != null) {
        final message = jsonEncode({"content": finalContent, "type": msgType});
        _channel!.sink.add(message);
      } else {
        _updateMessageStatus(tempId, 'error');
      }
    } catch (e) {
      print("🚨 Error al subir media: $e");
      _updateMessageStatus(tempId, 'error');
    }
  }

  Future<void> resendMessage(String msgId) async {
    final msgIndex = state.indexWhere((m) => m.id == msgId);
    if (msgIndex == -1) return;
    
    final msg = state[msgIndex];
    if (msg.status != 'error') return;

    _updateMessageStatus(msgId, 'pending');

    if (msg.messageType == 'text' || msg.messageType == 'location') {
       sendMessage(msg.content, msg.messageType);
    } else {
       try {
         final repository = ref.read(chatRepositoryProvider);
         final paths = msg.content.split(',');
         List<String> uploadedUrls = [];
         
         for (final p in paths) {
            final url = await repository.uploadChatMedia(conversationId, p);
            if (url == null) throw Exception();
            uploadedUrls.add(url);
         }
         
         if (_channel != null) {
           final wsMessage = jsonEncode({"content": uploadedUrls.join(','), "type": msg.messageType});
           _channel!.sink.add(wsMessage);
         } else {
           _updateMessageStatus(msgId, 'error');
         }
       } catch (e) {
         _updateMessageStatus(msgId, 'error');
       }
    }
  }

  void _updateMessageStatus(String msgId, String status) {
    state = state.map<MessageEntity>((msg) {
      if (msg.id == msgId) {
        return MessageModel(
          id: msg.id,
          senderId: msg.senderId,
          content: msg.content,
          messageType: msg.messageType,
          createdAt: msg.createdAt,
          status: status,
        );
      }
      return msg;
    }).toList();
  }

  void sendLocation() {
     if (_channel != null) {
      // Usamos una ubicación de México como placeholder simulado
      final message = jsonEncode({"content": "19.4326,-99.1332", "type": "location"});
      _channel!.sink.add(message);
    }
  }

  Future<void> sendOffer(double amount) async {
    try {
      state = state.map((msg) {
        if (msg.messageType == 'offer' && msg.status == 'pending') {
          return MessageModel(
            id: msg.id,
            senderId: msg.senderId,
            content: msg.content,
            messageType: msg.messageType,
            createdAt: msg.createdAt,
            status: 'withdrawn',
          );
        }
        return msg;
      }).toList();

      await sendOfferUseCase(conversationId, amount);
    } catch (e) {
      print("🚨 Error al enviar la oferta: $e");
    }
  }

  Future<void> respondOffer(String messageId, String action) async {
    try {
      await respondOfferUseCase(messageId, action);
      
      state = state.map((msg) {
        if (msg.id == messageId) {
           return MessageModel(
            id: msg.id,
            senderId: msg.senderId,
            content: msg.content,
            messageType: msg.messageType,
            createdAt: msg.createdAt,
            status: action == 'accept' ? 'accepted' : 'rejected',
          );
        }
        return msg;
      }).toList();

    } catch (e) {
      print("🚨 Error al responder la oferta: $e");
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _typingTimer?.cancel();
    _channel?.sink.close();
    super.dispose();
  }
}
