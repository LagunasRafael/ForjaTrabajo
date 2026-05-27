import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:forja_trabajo/core/network/api_client.dart';
import 'package:forja_trabajo/core/network/fcm_service.dart';

final notificationControllerProvider =
    StateNotifierProvider<NotificationController, bool>((ref) {
  return NotificationController();
});

class NotificationController extends StateNotifier<bool> {
  NotificationController() : super(true) {
    _loadPreference();
  }

  Future<void> _loadPreference() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool('notifications_enabled') ?? true;
  }

  Future<void> enable({String? userRole}) async {
    final fcm = FcmService();
    await fcm.enable(userRole: userRole);
    await fcm.initNotifications(userRole: userRole);
    final token = await fcm.getToken();
    if (token != null && token.isNotEmpty) {
      final apiClient = ApiClient();
      await apiClient.dio.put(
        '/auth/fcm-token',
        data: {'fcm_token': token},
      );
    }
    state = true;
  }

  Future<void> disable() async {
    state = false;
    await FcmService().disable();
    try {
      await ApiClient().dio.put(
        '/auth/fcm-token',
        data: {'fcm_token': ''},
      );
    } catch (_) {}
  }
}
