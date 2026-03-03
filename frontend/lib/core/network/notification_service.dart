import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

// Este handler debe ser una función top-level para manejar mensajes en background
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("Handling a background message: ${message.messageId}");
}

class NotificationService {
  FirebaseMessaging get _messaging => FirebaseMessaging.instance;

  Future<void> initNotifications() async {
    // 1. Solicitar permisos (Importante en iOS y versiones nuevas de Android)
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('Usuario aceptó los permisos de notificaciones');
    } else {
      debugPrint('Usuario rechazó o no ha aceptado los permisos');
    }

    // 2. Escuchar cuando la app está abierta (Foreground)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Recibida notificación en Foreground!');
      debugPrint('Message data: ${message.data}');

      if (message.notification != null) {
        debugPrint('Message title: ${message.notification?.title}');
        debugPrint('Message body: ${message.notification?.body}');

        // TODO: Aquí puedes mostrar un SnackBar o banner local
      }
    });

    // 3. Registrar el handler para Background
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  Future<String?> getToken() async {
    try {
      // Obtenemos el FCM Token de este dispositivo
      String? token = await _messaging.getToken();
      debugPrint("FCM Token del dispositivo: $token");
      return token;
    } catch (e) {
      debugPrint("Error obteniendo FCM Token: $e");
      return null;
    }
  }

  // Escucha cuando el token se refresca (ej. reinstalación)
  void listenToTokenChanges(Function(String) onTokenRefresh) {
    _messaging.onTokenRefresh.listen(onTokenRefresh);
  }
}
