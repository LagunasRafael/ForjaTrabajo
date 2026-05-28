import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:forja_trabajo/shared/utils/notification_navigation.dart';
import 'package:forja_trabajo/features/notifications/presentation/widgets/sleek_notification_banner.dart';

final FlutterLocalNotificationsPlugin _localNotifications =
    FlutterLocalNotificationsPlugin();

const AndroidNotificationChannel _channel = AndroidNotificationChannel(
  'forja_high_priority',
  'Alertas de Forja',
  description: 'Notificaciones importantes de mensajes y trabajos',
  importance: Importance.max,
  playSound: true,
  enableVibration: true,
);

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("📬 Background message: ${message.messageId}");

  final prefs = await SharedPreferences.getInstance();
  final enabled = prefs.getBool('notifications_enabled') ?? true;
  if (!enabled) {
    debugPrint('🔕 Notificaciones desactivadas, ignorando background message');
    return;
  }

  try {
    final localNotifications = FlutterLocalNotificationsPlugin();
    await localNotifications.initialize(const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    ));
    final title =
        message.notification?.title ?? message.data['title'] ?? 'ForjaTrabajo';
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
            channelDescription:
                'Notificaciones importantes de mensajes y trabajos',
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

Future<void> initLocalNotifications() async {
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

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    debugPrint('✅ Local Notifications inicializadas correctamente.');
  } catch (e) {
    debugPrint('❌ Error inicializando Local Notifications: $e');
  }
}

void showLocalNotification(RemoteMessage message) {
  final title = message.notification?.title ?? message.data['title'];
  final body = message.notification?.body ?? message.data['body'];
  if (title == null && body == null) return;

  try {
    final id = DateTime.now().millisecondsSinceEpoch ~/ 100;
    _localNotifications
        .show(
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
    )
        .then((_) => debugPrint('✅ Notificación local mostrada con ID: $id'))
        .catchError(
            (e) => debugPrint('⚠️ Error mostrando local notification: $e'));
  } catch (e) {
    debugPrint('⚠️ Error en showLocalNotification: $e');
  }
}

void showForegroundBanner(
  RemoteMessage message, {
  required GlobalKey<NavigatorState> navigatorKey,
}) {
  try {
    final navigator = navigatorKey.currentState;
    if (navigator == null) return;

    final title = message.data['title'] ?? 'ForjaTrabajo';
    final body = message.data['body'] ?? '';
    final type = message.data['type'] ?? '';
    final notifIcon = iconForNotificationType(type);

    final overlay = navigator.overlay!;
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (ctx) => Positioned(
        top: MediaQuery.of(ctx).padding.top + 12,
        left: 0,
        right: 0,
        child: Material(
          color: Colors.transparent,
          child: Dismissible(
            key: UniqueKey(),
            direction: DismissDirection.up,
            onDismissed: (_) {
              if (entry.mounted) entry.remove();
            },
            child: SleekNotificationBanner(
              title: title,
              body: body,
              icon: notifIcon,
              onTap: () {
                if (entry.mounted) entry.remove();
                final navContext = navigatorKey.currentContext;
                if (navContext == null) return;
                ProviderContainer? container;
                try {
                  container = ProviderScope.containerOf(navContext);
                } catch (_) {}
                navigateFromNotification(
                  context: navContext,
                  type: type,
                  conversationId: message.data['conversation_id'],
                  serviceId: message.data['service_id'],
                  senderName: message.data['sender_name'],
                  targetRole: message.data['target_role'],
                  container: container,
                );
              },
              onDismissed: () {
                if (entry.mounted) entry.remove();
              },
            ),
          ),
        ),
      ),
    );

    overlay.insert(entry);

    Future.delayed(const Duration(seconds: 5), () {
      if (entry.mounted) entry.remove();
    });
  } catch (e) {
    debugPrint('❌ [FCM] Error en banner: $e');
  }
}


