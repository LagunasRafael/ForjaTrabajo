import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:forja_trabajo/features/chat/presentation/screens/shared_chat_screen.dart';
import 'package:forja_trabajo/features/services/presentation/screens/client/offers_received_screen.dart';
import 'package:forja_trabajo/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:forja_trabajo/features/services/presentation/screens/client/my_requests_screen.dart';
import 'package:forja_trabajo/features/services/presentation/screens/worker/my_jobs_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forja_trabajo/features/chat/presentation/providers/chat_list_provider.dart';
import 'package:forja_trabajo/features/services/presentation/providers/nav_providers.dart';

/// Clave global para que el NotificationService pueda navegar sin BuildContext.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Provider para escuchar eventos de notificación de forma reactiva en cualquier parte de la app.
final notificationEventProvider = StreamProvider<RemoteMessage>((ref) {
  return NotificationService._onNotificationController.stream;
});

// Handler para mensajes en background/terminado (debe ser top-level)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("📬 Background message: ${message.messageId}");
}

class NotificationService {
  FirebaseMessaging get _messaging => FirebaseMessaging.instance;
  
  // 🔌 Local Notifications Plugin
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  // 📺 Canal de alta importancia para Android (EL POP)
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'forja_high_priority', // 🚀 ID NUEVO para forzar el banner flotante
    'Alertas de Forja', // name
    description: 'Notificaciones importantes de mensajes y trabajos',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  // 📢 Stream para avisar a las pantallas que algo cambió
  static final StreamController<RemoteMessage> _onNotificationController = StreamController<RemoteMessage>.broadcast();
  static Stream<RemoteMessage> get onNotification => _onNotificationController.stream;

  Future<void> initNotifications() async {
    // 1. Solicitar permisos (FCM)
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('🔔 Permisos notificaciones: ${settings.authorizationStatus}');

    // 2. Inicializar Local Notifications para el Pop-up (Android)
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await _localNotifications.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
    );

    // Crear el canal en Android
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // 3. Foreground: mostrar banner visual y REFRESCAR PROVIDERS
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('🚀 [FCM] ¡NOTIFICACIÓN RECIBIDA EN FOREGROUND!');
      debugPrint('🚀 Tipo: ${message.data['type']} | ID: ${message.messageId}');
      
      // Emitir el evento para que ChatList y otros refresquen
      _onNotificationController.add(message);
      
      // Mostrar el pop-up visual (el banner azul premium)
      _showForegroundBanner(message);
    });

    // 4. Background tap: app abierta desde segundo plano
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('📲 [FCM] APP ABIERTA DESDE NOTIFICACIÓN');
      _onNotificationController.add(message); // 🔄 Refresca ChatList también aquí
      _handleNotificationNavigation(message);
    });

    // 5. Registrar handler de background
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  void _showLocalNotification(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );
  }

  /// Llamar desde main() para manejar tap cuando la app estaba terminada.
  Future<void> handleInitialMessage() async {
    final message = await _messaging.getInitialMessage();
    if (message != null) {
      debugPrint('🚀 App iniciada desde notificación terminada');
      await Future.delayed(const Duration(milliseconds: 1200));
      _handleNotificationNavigation(message);
    }
  }

  /// Muestra un banner elegante en la parte superior cuando la app está en foreground.
  void _showForegroundBanner(RemoteMessage message) {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    final title = message.notification?.title ?? message.data['title'] ?? 'ForjaTrabajo';
    final body = message.notification?.body ?? message.data['body'] ?? '';
    final type = message.data['type'] ?? '';

    final IconData notifIcon = _iconForType(type);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        padding: EdgeInsets.zero,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.height - 150, 
          left: 10,
          right: 10,
        ),
        dismissDirection: DismissDirection.up,
        content: GestureDetector(
          onTap: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            _handleNotificationNavigation(message);
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1B4B),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4F46E5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(notifIcon, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (body.isNotEmpty)
                        Text(
                          body,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: Colors.white54, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleNotificationNavigation(RemoteMessage message) {
    final data = message.data;
    final type = data['type'] ?? '';
    final navigator = navigatorKey.currentState;
    final context = navigatorKey.currentContext;
    if (navigator == null || context == null) return;

    // Usamos el ProviderContainer global para modificar estados sin depender del widget tree
    final container = ProviderScope.containerOf(context);

    if (type == 'new_message' || type == 'new_offer' || type == 'admin_message' || type == 'dispute_opened') {
      final conversationId = data['conversation_id'];
      if (conversationId != null) {
        // 🔄 Refrescar la lista de chats globalmente
        container.read(chatListProvider.notifier).loadRealChats();
        
        navigator.push(
          MaterialPageRoute(
            builder: (_) => SharedChatScreen(
              conversationId: conversationId,
              otherUserName: data['sender_name'] ?? 'Chat Soporte',
            ),
          ),
        );
      }
    } else if (type == 'new_application') {
      final serviceId = data['service_id'];
      if (serviceId != null) {
        navigator.push(MaterialPageRoute(builder: (_) => OffersReceivedScreen(serviceId: serviceId)));
      } else {
        switch (type) {
          case 'new_request':
            // Ir a Mis Solicitudes -> Pestaña Postulaciones (1)
            container.read(clientNavProvider.notifier).state = 3;
            container.read(myRequestsTabProvider.notifier).state = 1;
            navigatorKey.currentState?.pushNamed('/my_requests');
            break;

          case 'job_accepted':
          case 'in_progress':
            // Ir a Mis Empleos -> En Proceso (1)
            container.read(workerNavProvider.notifier).state = 1;
            container.read(workerJobsTabProvider.notifier).state = 1;
            navigatorKey.currentState?.pushNamed('/my_jobs');
            break;

          case 'job_completed':
          case 'job_cancelled':
            // Ir a Mis Empleos -> Finalizados (2)
            container.read(workerNavProvider.notifier).state = 1;
            container.read(workerJobsTabProvider.notifier).state = 2;
            navigatorKey.currentState?.pushNamed('/my_jobs');
            break;

          case 'general':
          default:
            // Pantalla de notificaciones general
            navigatorKey.currentState?.push(
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            );
            break;
        }
      }
    } else if (type == 'job_completed') {
      // ✅ Trabajador: Mis Trabajos (Index 1) -> Historial (Index 2)
      container.read(workerNavProvider.notifier).state = 1;
      container.read(workerJobsTabProvider.notifier).state = 2;
      navigator.push(MaterialPageRoute(builder: (_) => const MyJobsScreen(initialIndex: 2)));
    } else if (type == 'job_waiting_confirmation') {
      // ✅ Cliente: Mis Trabajos (Index 3) -> En Proceso (Index 1)
      container.read(clientNavProvider.notifier).state = 3;
      container.read(myRequestsTabProvider.notifier).state = 1;
      navigator.push(MaterialPageRoute(builder: (_) => const MyRequestsScreen(initialIndex: 1)));
    } else if (type == 'job_cancelled') {
      container.read(workerNavProvider.notifier).state = 1;
      container.read(workerJobsTabProvider.notifier).state = 2;
      navigator.push(MaterialPageRoute(builder: (_) => const MyJobsScreen(initialIndex: 2)));
    } else if (type == 'offer_responded' || type == 'new_offer') {
      final conversationId = data['conversation_id'];
      if (conversationId != null) {
        navigator.push(MaterialPageRoute(builder: (_) => SharedChatScreen(conversationId: conversationId, otherUserName: data['sender_name'] ?? 'Chat')));
      }
    } else {
      navigator.push(MaterialPageRoute(builder: (_) => const NotificationsScreen()));
    }
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'new_message':
        return Icons.chat_bubble_rounded;
      case 'new_offer':
        return Icons.local_offer_rounded;
      case 'new_application':
        return Icons.person_add_rounded;
      case 'job_accepted':
        return Icons.check_circle_rounded;
      case 'job_waiting_confirmation':
        return Icons.hourglass_bottom_rounded;
      case 'job_completed':
        return Icons.verified_rounded;
      case 'job_cancelled':
        return Icons.cancel_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Future<String?> getToken() async {
    try {
      final token = await _messaging.getToken();
      debugPrint("🔑 FCM Token: $token");
      return token;
    } catch (e) {
      debugPrint("❌ Error obteniendo FCM Token: $e");
      return null;
    }
  }

  void listenToTokenChanges(Function(String) onTokenRefresh) {
    _messaging.onTokenRefresh.listen(onTokenRefresh);
  }
}
