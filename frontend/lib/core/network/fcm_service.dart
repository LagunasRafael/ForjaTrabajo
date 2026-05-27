import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:forja_trabajo/core/network/notification_service.dart';
import 'package:forja_trabajo/core/network/notification_display.dart';
import 'package:forja_trabajo/shared/utils/notification_navigation.dart';

class FcmService {
  static final FcmService _instance = FcmService._();
  factory FcmService() => _instance;
  FcmService._();

  FirebaseMessaging get _messaging => FirebaseMessaging.instance;
  String? _currentUserRole;
  bool _initialized = false;
  bool _enabled = true;

  bool get isEnabled => _enabled;

  Future<void> disable() async {
    _enabled = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', false);
  }

  Future<void> enable({String? userRole}) async {
    _enabled = true;
    _currentUserRole = userRole;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', true);
  }

  Future<void> initNotifications({String? userRole}) async {
    if (_initialized) return;
    _initialized = true;

    _currentUserRole = userRole;

    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool('notifications_enabled') ?? true;

    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('🔔 Permisos notificaciones: ${settings.authorizationStatus}');

    await initLocalNotifications();

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (!_enabled) return;
      if (!_shouldHandleMessage(message)) return;

      onNotificationController.add(message);
      showForegroundBanner(message, navigatorKey: navigatorKey);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (!_enabled) return;
      if (!_shouldHandleMessage(message)) return;

      debugPrint('📲 [FCM] APP ABIERTA DESDE NOTIFICACIÓN');
      onNotificationController.add(message);
      _navigateFromMessage(message);
    });

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  bool _shouldHandleMessage(RemoteMessage message) {
    final targetRole = message.data['target_role'];
    if (targetRole == null || targetRole.isEmpty) return true;
    if (_currentUserRole == null) return true;
    return targetRole == _currentUserRole;
  }

  Future<void> handleInitialMessage() async {
    final message = await _messaging.getInitialMessage();
    if (message != null && _shouldHandleMessage(message)) {
      debugPrint('🚀 App iniciada desde notificación terminada');
      await Future.delayed(const Duration(milliseconds: 1200));
      _navigateFromMessage(message);
    }
  }

  void _navigateFromMessage(RemoteMessage message) {
    try {
      final data = message.data;
      final type = data['type'] ?? '';
      final context = navigatorKey.currentContext;
      if (context == null) {
        debugPrint('⚠️ [FcmService] Context no disponible.');
        return;
      }

      ProviderContainer? container;
      try {
        container = ProviderScope.containerOf(context);
      } catch (e) {
        debugPrint(
            '⚠️ [FcmService] No se pudo obtener el ProviderContainer: $e');
      }

      navigateFromNotification(
        context: context,
        type: type,
        conversationId: data['conversation_id'],
        serviceId: data['service_id'],
        senderName: data['sender_name'],
        targetRole: data['target_role'],
        container: container,
      );
    } catch (e) {
      debugPrint('❌ [FCM] Error navegando desde notificación: $e');
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
