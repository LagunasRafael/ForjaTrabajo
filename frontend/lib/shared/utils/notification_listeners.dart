import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:forja_trabajo/core/network/notification_service.dart';
import 'package:forja_trabajo/features/auth/presentation/providers/auth_provider.dart';
import 'package:forja_trabajo/features/chat/presentation/providers/chat_list_provider.dart';
import 'package:forja_trabajo/features/notifications/presentation/providers/notification_provider.dart';
import 'package:forja_trabajo/features/services/presentation/providers/job_management_provider.dart';
import 'package:forja_trabajo/features/services/presentation/providers/service_list_provider.dart';

final notificationListenerProvider = Provider<void>((ref) {
  ref.listen(notificationEventProvider, (previous, next) {
    next.whenData((message) => _onNotification(ref, message));
  });
  return;
});

void _onNotification(Ref ref, RemoteMessage message) {
  final type = message.data['type'] ?? '';

  final role = ref.read(authProvider).user?.role;
  ref.invalidate(notificationListProvider(role));

  if (type == 'new_message' || type == 'admin_message' || type == 'dispute_opened' || type == 'new_offer') {
    ref.read(chatListProvider.notifier).loadRealChats();
  }

  if (type.toString().contains('job_') ||
      type == 'payment_expired' ||
      type == 'in_progress' ||
      type == 'new_application' ||
      type == 'offer_responded' ||
      type == 'new_offer') {
    ref.invalidate(workerJobsProvider);
    ref.invalidate(myRequestsProvider);
  }

  if (type == 'job_completed' || type == 'job_cancelled' || type == 'dispute_resolved') {
    ref.invalidate(chatListProvider);
  }

  if (type == 'new_service' || type == 'marketplace_refresh') {
    ref.invalidate(serviceListProvider);
  }
}
