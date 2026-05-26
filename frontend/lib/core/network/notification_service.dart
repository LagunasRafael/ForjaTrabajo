import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Clave global para que los servicios puedan navegar sin BuildContext.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Stream controller for notification events.
final StreamController<RemoteMessage> onNotificationController =
    StreamController<RemoteMessage>.broadcast();

/// Provider para escuchar eventos de notificación de forma reactiva.
final notificationEventProvider = StreamProvider<RemoteMessage>((ref) {
  return onNotificationController.stream;
});
