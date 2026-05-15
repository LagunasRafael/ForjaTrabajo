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
import 'package:forja_trabajo/features/services/presentation/providers/nav_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Clave global para que el NotificationService pueda navegar sin BuildContext.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

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
    'forja_notif_channel', // id
    'Notificaciones ForjaTrabajo', // name
    description: 'Canal para mensajes y actualizaciones importantes', // description
    importance: Importance.max,
    playSound: true,
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
      onDidReceiveNotificationResponse: (details) {
        // Manejar el tap en la notificación local si es necesario
      },
    );

    // Crear el canal en Android
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // 3. Foreground: mostrar banner visual
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('📩 Notificación en foreground: ${message.notification?.title}');
      
      // Emitir el evento para que las pantallas se actualicen
      _onNotificationController.add(message);
      
      // MOSTRAR EL POP-UP NATIVO
      _showLocalNotification(message);
    });

    // 4. Background tap: app abierta desde segundo plano
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('📲 App abierta desde background por notificación');
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
    if (navigator == null) return;

    if (type == 'new_message' || type == 'new_offer' || type == 'admin_message' || type == 'dispute_opened') {
      final conversationId = data['conversation_id'];
      if (conversationId != null) {
        navigator.push(
          MaterialPageRoute(
            builder: (_) => SharedChatScreen(
              conversationId: conversationId,
              otherUserName: data['sender_name'] ?? 'Chat Soporte',
            ),
          ),
        );
      } else {
        navigator.push(
          MaterialPageRoute(builder: (_) => const NotificationsScreen()),
        );
      }
    } else if (type == 'job_accepted') {
      // El trabajador va a sus trabajos "En Curso" (Index 1)
      navigator.push(
        MaterialPageRoute(builder: (_) => const MyJobsScreen(initialIndex: 1)),
      );
    } else if (type == 'job_completed' || type == 'job_cancelled') {
      // Si es cliente va a Finalizados (Index 2), si es trabajador va a Historial (Index 2)
      // Nota: Aquí asumimos que el usuario actual es el receptor
      navigator.push(
        MaterialPageRoute(builder: (_) => const MyJobsScreen(initialIndex: 2)),
      );
    } else if (type == 'job_waiting_confirmation') {
      // El cliente va a "En Proceso" (Index 1) para confirmar
      navigator.push(
        MaterialPageRoute(builder: (_) => const MyRequestsScreen(initialIndex: 1)),
      );
    } else if (type == 'new_application') {
      final serviceId = data['service_id'];
      if (serviceId != null) {
        navigator.push(
          MaterialPageRoute(
            builder: (_) => OffersReceivedScreen(serviceId: serviceId),
          ),
        );
      } else {
        navigator.push(
          MaterialPageRoute(builder: (_) => const NotificationsScreen()),
        );
      }
    } else {
      // Por defecto, llevar a la lista de notificaciones si no es un chat específico
      navigator.push(
        MaterialPageRoute(builder: (_) => const NotificationsScreen()),
      );
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
