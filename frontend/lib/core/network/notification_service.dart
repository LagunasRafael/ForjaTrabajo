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
  try {
    final localNotifications = FlutterLocalNotificationsPlugin();
    await localNotifications.initialize(const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    ));
    final title = message.notification?.title ?? message.data['title'] ?? 'ForjaTrabajo';
    final body = message.notification?.body ?? message.data['body'] ?? '';
    if (title != 'ForjaTrabajo' || body.isNotEmpty) {
      await localNotifications.show(
        message.hashCode,
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'forja_high_priority',
            'Alertas de Forja',
            channelDescription: 'Notificaciones importantes de mensajes y trabajos',
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
        ),
      );
    }
  } catch (e) {
    debugPrint('⚠️ Error mostrando notificación en background: $e');
  }
}

class NotificationService {
  FirebaseMessaging get _messaging => FirebaseMessaging.instance;
  
  // 🔌 Local Notifications Plugin
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  String? _currentUserRole;

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

  Future<void> initNotifications({String? userRole}) async {
    _currentUserRole = userRole;
    
    // 1. Solicitar permisos (FCM)
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('🔔 Permisos notificaciones: ${settings.authorizationStatus}');

    // 2. Inicializar Local Notifications para el Pop-up (Android)
    try {
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosInit = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      
      await _localNotifications.initialize(
        const InitializationSettings(android: androidInit, iOS: iosInit),
        onDidReceiveNotificationResponse: (response) {
          debugPrint('🎯 Tap en notificación local: ${response.payload}');
        },
      );

      // Crear el canal en Android
      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_channel);
      
      debugPrint('✅ Local Notifications inicializadas correctamente.');
    } catch (e) {
      debugPrint('❌ Error inicializando Local Notifications: $e');
      // No lanzamos el error para que la app pueda seguir funcionando sin notificaciones locales
    }

    // 3. Foreground: mostrar notificación del sistema + banner visual + REFRESCAR PROVIDERS
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (!_shouldHandleMessage(message)) return;
      
      debugPrint('🚀 [FCM] ¡NOTIFICACIÓN RECIBIDA EN FOREGROUND!');
      debugPrint('🚀 Tipo: ${message.data['type']} | ID: ${message.messageId}');
      
      _showLocalNotification(message);
      _onNotificationController.add(message);
      
      try {
        _showForegroundBanner(message);
      } catch (e) {
        debugPrint('❌ [FCM] Error mostrando banner foreground: $e');
      }
    });

    // 4. Background tap: app abierta desde segundo plano
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (!_shouldHandleMessage(message)) return;
      
      debugPrint('📲 [FCM] APP ABIERTA DESDE NOTIFICACIÓN');
      _onNotificationController.add(message);
      try {
        _handleNotificationNavigation(message);
      } catch (e) {
        debugPrint('❌ [FCM] Error navegando desde onMessageOpenedApp: $e');
      }
    });

    // 5. Registrar handler de background
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  /// Verifica si la notificación debe manejarse según el rol del usuario.
  bool _shouldHandleMessage(RemoteMessage message) {
    final targetRole = message.data['target_role'];
    if (targetRole == null || targetRole.isEmpty) return true;
    if (_currentUserRole == null) return true;
    return targetRole == _currentUserRole;
  }

  void _showLocalNotification(RemoteMessage message) {
    final title = message.notification?.title ?? message.data['title'];
    final body = message.notification?.body ?? message.data['body'];
    if (title == null && body == null) return;

    try {
      final id = DateTime.now().millisecondsSinceEpoch ~/ 100;
      _localNotifications.show(
        id,
        title ?? 'ForjaTrabajo',
        body ?? '',
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
      ).then((_) => debugPrint('✅ Notificación local mostrada con ID: $id'))
       .catchError((e) => debugPrint('⚠️ Error mostrando local notification: $e'));
    } catch (e) {
      debugPrint('⚠️ Error en _showLocalNotification: $e');
    }
  }

  /// Llamar desde main() para manejar tap cuando la app estaba terminada.
  Future<void> handleInitialMessage() async {
    final message = await _messaging.getInitialMessage();
    if (message != null && _shouldHandleMessage(message)) {
      debugPrint('🚀 App iniciada desde notificación terminada');
      await Future.delayed(const Duration(milliseconds: 1200));
      _handleNotificationNavigation(message);
    }
  }

  void _showForegroundBanner(RemoteMessage message) {
    try {
      final context = navigatorKey.currentContext;
      if (context == null || !context.mounted) return;

      final title = message.notification?.title ?? message.data['title'] ?? 'ForjaTrabajo';
      final body = message.notification?.body ?? message.data['body'] ?? '';
      final type = message.data['type'] ?? '';

      final IconData notifIcon = _iconForType(type);

      final overlayState = Overlay.of(context);
      late OverlayEntry overlayEntry;

      overlayEntry = OverlayEntry(
        builder: (context) => Positioned(
          top: MediaQuery.of(context).padding.top + 16,
          left: 16,
          right: 16,
          child: Material(
            color: Colors.transparent,
            child: Dismissible(
              key: UniqueKey(),
              direction: DismissDirection.up,
              onDismissed: (_) {
                if (overlayEntry.mounted) overlayEntry.remove();
              },
              child: GestureDetector(
                onTap: () {
                  if (overlayEntry.mounted) overlayEntry.remove();
                  _handleNotificationNavigation(message);
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1B4B),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4)),
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
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      overlayState.insert(overlayEntry);

      Future.delayed(const Duration(seconds: 4), () {
        if (overlayEntry.mounted) {
          overlayEntry.remove();
        }
      });
    } catch (e) {
      debugPrint('❌ [FCM] Error en _showForegroundBanner: $e');
    }
  }

  void _handleNotificationNavigation(RemoteMessage message) {
    try {
      final data = message.data;
      final type = data['type'] ?? '';
      final navigator = navigatorKey.currentState;
      final context = navigatorKey.currentContext;
      if (navigator == null || context == null) {
        debugPrint('⚠️ [NotificationService] Navigator o Context no disponibles.');
        return;
      }

    // Intentamos obtener el container de Riverpod de forma segura
    ProviderContainer? container;
    try {
      container = ProviderScope.containerOf(context);
    } catch (e) {
      debugPrint('⚠️ [NotificationService] No se pudo obtener el ProviderContainer: $e');
    }

    if (type == 'new_message' || type == 'new_offer' || type == 'admin_message' || type == 'dispute_opened') {
      final conversationId = data['conversation_id'];
      if (conversationId != null) {
        // 🔄 Refrescar la lista de chats globalmente
        if (container != null) {
          container.read(chatListProvider.notifier).loadRealChats();
        }
        
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
        container?.read(clientNavProvider.notifier).state = 3;
        container?.read(myRequestsTabProvider.notifier).state = 0;
        navigator.push(MaterialPageRoute(builder: (_) => const MyRequestsScreen(initialIndex: 0)));
      }
    } else if (type == 'job_accepted' || type == 'in_progress') {
      // ✅ Trabajador: Mis Empleos -> En Proceso (1)
      container?.read(workerNavProvider.notifier).state = 1;
      container?.read(workerJobsTabProvider.notifier).state = 1;
      navigator.push(MaterialPageRoute(builder: (_) => const MyJobsScreen(initialIndex: 1)));
    } else if (type == 'job_completed') {
      // ✅ Trabajador: Mis Trabajos -> Historial (2)
      container?.read(workerNavProvider.notifier).state = 1;
      container?.read(workerJobsTabProvider.notifier).state = 2;
      navigator.push(MaterialPageRoute(builder: (_) => const MyJobsScreen(initialIndex: 2)));
    } else if (type == 'job_waiting_confirmation') {
      // ✅ Cliente: Mis Trabajos -> En Proceso (1)
      container?.read(clientNavProvider.notifier).state = 3;
      container?.read(myRequestsTabProvider.notifier).state = 1;
      navigator.push(MaterialPageRoute(builder: (_) => const MyRequestsScreen(initialIndex: 1)));
    } else if (type == 'job_cancelled' || type == 'payment_expired') {
      final targetRole = data['target_role'];
      if (targetRole == 'client') {
        container?.read(clientNavProvider.notifier).state = 3;
        container?.read(myRequestsTabProvider.notifier).state = 0;
        navigator.push(MaterialPageRoute(builder: (_) => const MyRequestsScreen(initialIndex: 0)));
      } else {
        container?.read(workerNavProvider.notifier).state = 1;
        container?.read(workerJobsTabProvider.notifier).state = 2;
        navigator.push(MaterialPageRoute(builder: (_) => const MyJobsScreen(initialIndex: 2)));
      }
    } else if (type == 'payment_deadline') {
      // ✅ Cliente: ir a En Proceso para pagar
      container?.read(clientNavProvider.notifier).state = 3;
      container?.read(myRequestsTabProvider.notifier).state = 1;
      navigator.push(MaterialPageRoute(builder: (_) => const MyRequestsScreen(initialIndex: 1)));
    } else if (type == 'confirmation_deadline') {
      // ✅ Trabajador: ir a En Proceso
      container?.read(workerNavProvider.notifier).state = 1;
      container?.read(workerJobsTabProvider.notifier).state = 1;
      navigator.push(MaterialPageRoute(builder: (_) => const MyJobsScreen(initialIndex: 1)));
    } else if (type == 'payment_held' || type == 'payment_released') {
      // ✅ Trabajador: le avisamos que ya pagaron
      final targetRole = data['target_role'];
      if (targetRole == 'worker') {
        container?.read(workerNavProvider.notifier).state = 1;
        container?.read(workerJobsTabProvider.notifier).state = 1;
        navigator.push(MaterialPageRoute(builder: (_) => const MyJobsScreen(initialIndex: 1)));
      } else {
        container?.read(clientNavProvider.notifier).state = 3;
        container?.read(myRequestsTabProvider.notifier).state = 1;
        navigator.push(MaterialPageRoute(builder: (_) => const MyRequestsScreen(initialIndex: 1)));
      }
    } else if (type == 'auto_released') {
      final targetRole = data['target_role'];
      if (targetRole == 'worker') {
        container?.read(workerNavProvider.notifier).state = 1;
        container?.read(workerJobsTabProvider.notifier).state = 2;
        navigator.push(MaterialPageRoute(builder: (_) => const MyJobsScreen(initialIndex: 2)));
      } else {
        container?.read(clientNavProvider.notifier).state = 3;
        container?.read(myRequestsTabProvider.notifier).state = 2;
        navigator.push(MaterialPageRoute(builder: (_) => const MyRequestsScreen(initialIndex: 2)));
      }
    } else if (type == 'payment_refunded') {
      final targetRole = data['target_role'];
      if (targetRole == 'client') {
        container?.read(clientNavProvider.notifier).state = 3;
        container?.read(myRequestsTabProvider.notifier).state = 2;
        navigator.push(MaterialPageRoute(builder: (_) => const MyRequestsScreen(initialIndex: 2)));
      } else {
        container?.read(workerNavProvider.notifier).state = 1;
        container?.read(workerJobsTabProvider.notifier).state = 2;
        navigator.push(MaterialPageRoute(builder: (_) => const MyJobsScreen(initialIndex: 2)));
      }
    } else if (type == 'offer_responded' || type == 'new_offer') {
      final conversationId = data['conversation_id'];
      if (conversationId != null) {
        navigator.push(MaterialPageRoute(builder: (_) => SharedChatScreen(conversationId: conversationId, otherUserName: data['sender_name'] ?? 'Chat')));
      }
    } else {
      navigator.push(MaterialPageRoute(builder: (_) => const NotificationsScreen()));
    }
    } catch (e) {
      debugPrint('❌ [FCM] Error navegando desde notificación: $e');
    }
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'new_message':
        return Icons.chat_bubble_rounded;
      case 'new_offer':
        return Icons.local_offer_rounded;
      case 'offer_responded':
        return Icons.handshake_rounded;
      case 'new_application':
        return Icons.person_add_rounded;
      case 'job_accepted':
      case 'in_progress':
        return Icons.check_circle_rounded;
      case 'job_waiting_confirmation':
        return Icons.hourglass_bottom_rounded;
      case 'job_completed':
        return Icons.verified_rounded;
      case 'job_cancelled':
        return Icons.cancel_rounded;
      case 'payment_deadline':
        return Icons.timer_rounded;
      case 'confirmation_deadline':
        return Icons.schedule_rounded;
      case 'payment_expired':
        return Icons.timer_off_rounded;
      case 'payment_held':
      case 'payment_released':
        return Icons.payments_rounded;
      case 'payment_refunded':
        return Icons.currency_exchange_rounded;
      case 'auto_released':
        return Icons.autorenew_rounded;
      case 'dispute_opened':
        return Icons.gavel_rounded;
      case 'dispute_resolved':
        return Icons.checklist_rounded;
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
