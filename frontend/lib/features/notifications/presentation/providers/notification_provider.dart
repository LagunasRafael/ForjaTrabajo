import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/notification_remote_datasource.dart';
import '../../data/repositories/notification_repository_impl.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/repositories/notification_repository.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/notification_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

// --- DEPENDENCY INJECTION ---

final notificationRemoteDataSourceProvider = Provider<NotificationRemoteDataSource>((ref) {
  // ApiClient is a singleton
  final apiClient = ApiClient();
  return NotificationRemoteDataSource(apiClient);
});

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  final dataSource = ref.watch(notificationRemoteDataSourceProvider);
  return NotificationRepositoryImpl(dataSource);
});

// --- STATE NOTIFIER ---

class NotificationNotifier extends StateNotifier<AsyncValue<List<NotificationEntity>>> {
  final NotificationRepository _repository;
  final String? role;
  StreamSubscription? _pushSubscription;

  NotificationNotifier(this._repository, this.role) : super(const AsyncValue.loading()) {
    fetchNotifications();

    // 🔔 Escuchar push notifications en foreground para refrescar la lista
    _pushSubscription = NotificationService.onNotification.listen((_) {
      // Cada vez que llega una push, re-fetch desde el servidor
      fetchNotifications();
    });
  }

  @override
  void dispose() {
    _pushSubscription?.cancel();
    super.dispose();
  }

  Future<void> fetchNotifications() async {
    try {
      state = const AsyncValue.loading();
      final notifications = await _repository.getNotifications(role: role);
      state = AsyncValue.data(notifications);

    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _repository.markAsRead(notificationId);
      // Optimistic update
      if (state is AsyncData) {
        final currentList = state.value!;
        state = AsyncValue.data(
          currentList.map((n) {
            if (n.id == notificationId) {
              return n.copyWith(isRead: true);
            }
            return n;
          }).toList(),
        );
      }
    } catch (e) {
      print("Error marking as read: $e");
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _repository.markAllAsRead();
      // Optimistic update
      if (state is AsyncData) {
        final currentList = state.value!;
        state = AsyncValue.data(
          currentList.map((n) => n.copyWith(isRead: true)).toList(),
        );
      }
    } catch (e) {
      print("Error marking all as read: $e");
    }
  }
}

final notificationListProvider = StateNotifierProvider.family<NotificationNotifier, AsyncValue<List<NotificationEntity>>, String?>((ref, role) {
  final repository = ref.watch(notificationRepositoryProvider);
  return NotificationNotifier(repository, role);
});


// --- UNREAD COUNT FOR NOTIFICATIONS ---
final unreadNotificationCountProvider = Provider<int>((ref) {
  final authState = ref.watch(authProvider);
  final notificationState = ref.watch(notificationListProvider(authState.user?.role));
  return notificationState.maybeWhen(
    data: (notifications) => notifications.where((n) => !n.isRead).length,
    orElse: () => 0,
  );
});

