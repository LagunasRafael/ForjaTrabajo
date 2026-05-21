import 'package:dio/dio.dart';
import '../models/notification_model.dart';
import '../../../../core/network/api_client.dart';

class NotificationRemoteDataSource {
  final ApiClient _apiClient;

  NotificationRemoteDataSource(this._apiClient);

  Future<List<NotificationModel>> getNotifications({String? role}) async {
    try {
      final response = await _apiClient.dio.get(
        '/services/notifications/',
        queryParameters: role != null ? {'role': role} : null,
      );
      if (response.statusCode == 200) {
        return (response.data as List)
            .map((e) => NotificationModel.fromJson(e))
            .toList();
      }
      throw Exception('Failed to load notifications');
    } catch (e) {
      throw Exception('Error fetching notifications: $e');
    }
  }


  Future<void> markAsRead(String notificationId) async {
    try {
      await _apiClient.dio.put('/services/notifications/$notificationId/read');
    } catch (e) {
      throw Exception('Error marking notification as read: $e');
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _apiClient.dio.put('/services/notifications/read-all');
    } catch (e) {
      throw Exception('Error marking all notifications as read: $e');
    }
  }
}
