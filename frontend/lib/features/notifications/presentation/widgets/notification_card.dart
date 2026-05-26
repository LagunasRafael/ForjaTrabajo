import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../domain/entities/notification_entity.dart';
import '../providers/notification_provider.dart';
import 'package:forja_trabajo/features/auth/presentation/providers/auth_provider.dart';
import 'package:forja_trabajo/shared/utils/notification_navigation.dart';

class NotificationCard extends ConsumerWidget {
  final NotificationEntity notification;

  const NotificationCard({super.key, required this.notification});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isUnread = !notification.isRead;

    return Container(
      decoration: BoxDecoration(
        color: isUnread ? Colors.blue.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isUnread ? Border.all(color: Colors.blue.withValues(alpha: 0.3), width: 1) : Border.all(color: Colors.grey.withValues(alpha: 0.1), width: 1),
        boxShadow: [
          if (!isUnread)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _handleTap(context, ref),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorForNotificationType(notification.type).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(iconForNotificationType(notification.type), color: colorForNotificationType(notification.type), size: 26),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.title,
                        style: TextStyle(
                          fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                          fontSize: 16,
                          color: isUnread ? Colors.black : Colors.black87,
                        ),
                      ),
                      if (notification.body != null && notification.body!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          _formatBody(notification.body!),
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 14,
                            height: 1.3,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        timeago.format(notification.createdAt, locale: 'es'),
                        style: TextStyle(color: Colors.grey[500], fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                if (isUnread)
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.blue,
                      boxShadow: [
                        BoxShadow(color: Colors.blue.withValues(alpha: 0.4), blurRadius: 4, spreadRadius: 1)
                      ]
                    ),
                  )
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleTap(BuildContext context, WidgetRef ref) {
    if (!notification.isRead) {
      final role = ref.read(authProvider).user?.role;
      ref.read(notificationListProvider(role).notifier).markAsRead(notification.id);
    }

    final type = notification.type;
    final refId = notification.referenceId;

    String otherName = 'Usuario';
    if (type == 'new_offer' || type == 'offer_responded') {
      final body = notification.body ?? '';
      final namePart = body.split(RegExp(r'\s+(ha realizado|aceptó|rechazó)\s+'));
      if (namePart.length >= 2) {
        otherName = namePart[0].trim();
      }
    } else if (type == 'new_message') {
      final namePart = notification.title.split(' de ');
      if (namePart.length >= 2) {
        otherName = namePart.sublist(1).join(' de ').trim();
      }
    }

    final container = ProviderScope.containerOf(context);
    final isWalletType = type == 'payment_released' || type == 'auto_released' || type == 'payment_held';

    navigateFromNotification(
      context: context,
      type: type,
      conversationId: (type == 'new_message' || type == 'new_offer' || type == 'offer_responded') ? refId : null,
      serviceId: type == 'new_application' ? refId : null,
      senderName: otherName,
      container: container,
      clearStack: true,
      navigateToWallet: isWalletType,
    );
  }

  String _formatBody(String body) {
    final regex = RegExp(r'\$(\d+)\.0{1,2}\b');
    return body.replaceAllMapped(regex, (match) => '\$${match.group(1)}');
  }
}
