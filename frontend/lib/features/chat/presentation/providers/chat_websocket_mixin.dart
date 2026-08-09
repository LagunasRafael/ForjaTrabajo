import 'dart:async';
import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forja_trabajo/features/chat/domain/repositories/chat_repository.dart';
import 'package:forja_trabajo/features/chat/data/models/message_model.dart';
import 'package:forja_trabajo/features/chat/presentation/providers/chat_list_provider.dart';
import 'package:forja_trabajo/core/network/api_client.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:forja_trabajo/features/chat/presentation/providers/chat_typing_provider.dart';
import 'package:forja_trabajo/features/services/presentation/providers/job_management_provider.dart';

mixin ChatWebSocketMixin on StateNotifier<List<MessageModel>>, WidgetsBindingObserver {
  ChatRepository get repository;
  String get conversationId;
  String get userId;
  Ref get ref;
  bool get isDisposed;

  WebSocketChannel? wsChannel;
  bool wsReconnecting = false;
  int _wsRetryCount = 0;
  StreamSubscription? _wsStreamSubscription;
  Timer? _wsPingTimer;
  bool _wsLifecycleObserverAdded = false;

  bool get isConnected => wsChannel != null && !wsReconnecting;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !isConnected && !isDisposed) {
      print("📱 [WS] App reanudada, reconectando WebSocket...");
      wsReconnect();
    }
  }

  void _startPingTimer() {
    _wsPingTimer?.cancel();
    _wsPingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (wsChannel != null) {
        wsChannel!.sink.add(jsonEncode({"type": "ping"}));
      }
    });
    if (!_wsLifecycleObserverAdded) {
      WidgetsBinding.instance.addObserver(this);
      _wsLifecycleObserverAdded = true;
    }
  }

  void _stopPingTimer() {
    _wsPingTimer?.cancel();
    _wsPingTimer = null;
    if (_wsLifecycleObserverAdded) {
      WidgetsBinding.instance.removeObserver(this);
      _wsLifecycleObserverAdded = false;
    }
  }

  void wsConnect() {
    if (isDisposed || wsReconnecting || userId.isEmpty || conversationId.isEmpty) return;

    // Cerrar conexión anterior antes de crear una nueva
    _wsStreamSubscription?.cancel();
    _wsStreamSubscription = null;
    wsChannel?.sink.close();
    wsChannel = null;

    final apiBase = ApiClient.baseUrl;
    final wsBaseUrl = apiBase
        .replaceFirst('https://', 'wss://')
        .replaceFirst('http://', 'ws://');

    final wsUrl = "$wsBaseUrl/services/chat/ws/$conversationId/$userId";
    print("🔌 [WS] Conectando a: $wsUrl");
    
    try {
      wsChannel = WebSocketChannel.connect(Uri.parse(wsUrl));
      _startPingTimer();

      _wsStreamSubscription = wsChannel!.stream.listen(
        (message) {
          _wsRetryCount = 0;
          print("📥 [WS] Raw recibido: $message");
          wsHandleIncoming(message);
        },
        onError: (error) {
          print("❌ [WS] Error de conexión: $error");
          wsReconnect();
        },
        onDone: () {
          print("🔌 [WS] Conexión cerrada por el servidor");
          wsReconnect();
        },
        cancelOnError: false,
      );
    } catch (e) {
      print("🚨 [WS] Excepción al conectar: $e");
      wsReconnect();
    }
  }

  void wsHandleIncoming(dynamic message) {
    if (!mounted) return;

    try {
      final decoded = jsonDecode(message);

      final incomingConvoId = decoded['conversation_id']?.toString() ?? '';
      if (incomingConvoId.isNotEmpty && incomingConvoId != conversationId) {
        print("⏭️ Ignorando mensaje de otra conversación: $incomingConvoId");
        return;
      }

      if (decoded is Map && decoded['type'] == 'pong') {
        return;
      }

      if (decoded is Map && decoded['type'] == 'typing') {
        final senderId = decoded['sender_id'];
        if (senderId != userId) {
          ref.read(chatTypingProvider(conversationId).notifier).state = decoded['is_typing'] ?? false;
        }
        return;
      }

      if (decoded is Map && decoded['type'] == 'conversation_closed') {
        print("🔒 [WS] Chat cerrado: $conversationId, razón: ${decoded['closed_reason']}");
        ref.read(chatListProvider.notifier).loadRealChats();
        return;
      }

      if (decoded is Map && decoded['type'] == 'conversation_reactivated') {
        print("🔓 [WS] Chat reactivado: $conversationId");
        ref.read(chatListProvider.notifier).loadRealChats();
        return;
      }

      if (decoded is Map && decoded['type'] == 'job_accepted') {
        print("✅ [WS] Trabajo aceptado: job=${decoded['job_id']}");
        ref.invalidate(workerJobsProvider);
        ref.read(chatListProvider.notifier).loadRealChats();
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

      if (newMessage.messageType == 'system') {
        state = [newMessage, ...state];
        ref.read(chatListProvider.notifier).loadRealChats();
        repository.markAsRead(conversationId);
        return;
      }

      if (newMessage.senderId == userId) {
        int tempIdx = state.indexWhere((m) => m.id == newMessage.id);
        
        if (tempIdx == -1) {
          tempIdx = state.indexWhere((m) => m.id.startsWith('temp_') && m.content == newMessage.content);
        }
        
        if (tempIdx == -1 && ['image', 'gallery', 'audio', 'video'].contains(newMessage.messageType)) {
          tempIdx = state.indexWhere((m) => m.id.startsWith('temp_') && 
            (m.messageType == newMessage.messageType || 
             (newMessage.messageType == 'gallery' && m.messageType == 'image') ||
             (newMessage.messageType == 'image' && m.messageType == 'gallery')));
        }

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
      repository.markAsRead(conversationId);
    } catch (e) {
      print("🚨 Error procesando mensaje WS: $e");
    }
  }

  void wsReconnect() {
    if (!mounted || wsReconnecting) return;
    _stopPingTimer();
    wsReconnecting = true;
    _wsRetryCount++;

    _wsStreamSubscription?.cancel();
    _wsStreamSubscription = null;
    wsChannel?.sink.close();
    wsChannel = null;

    int delayMs = 1000 * (1 << _wsRetryCount);
    if (delayMs > 30000) delayMs = 30000;
    final delay = Duration(milliseconds: delayMs);
    print("🔄 [WS] Reintentando en ${delay.inMilliseconds}ms (intento $_wsRetryCount)");

    Future.delayed(delay, () {
      if (mounted) {
        wsReconnecting = false;
        wsConnect();
      }
    });
  }

  void wsDisconnect() {
    _stopPingTimer();
    _wsStreamSubscription?.cancel();
    _wsStreamSubscription = null;
    wsChannel?.sink.close();
    wsChannel = null;
  }

  void sendTyping(bool isTyping) {
    if (wsChannel == null) return;
    final message = jsonEncode({"type": "typing", "is_typing": isTyping});
    wsChannel!.sink.add(message);
  }
}
