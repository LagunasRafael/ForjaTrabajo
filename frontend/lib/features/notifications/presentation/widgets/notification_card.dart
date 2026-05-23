import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:forja_trabajo/features/chat/presentation/screens/shared_chat_screen.dart';
import 'package:forja_trabajo/features/services/presentation/screens/client/offers_received_screen.dart';
import '../../domain/entities/notification_entity.dart';
import '../providers/notification_provider.dart';
import 'package:forja_trabajo/features/services/presentation/providers/nav_providers.dart';
import 'package:forja_trabajo/features/auth/presentation/providers/auth_provider.dart';
import 'package:forja_trabajo/features/payments/presentation/screens/wallet_screen.dart';

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
                    color: _getColorForType(notification.type).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(_getIconForType(notification.type), color: _getColorForType(notification.type), size: 26),
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
    // Marcar como leída
    if (!notification.isRead) {
      final role = ref.read(authProvider).user?.role;
      ref.read(notificationListProvider(role).notifier).markAsRead(notification.id);
    }
    
    // NAVEGACIÓN SEGÚN EL TIPO
    final type = notification.type;
    final refId = notification.referenceId;

    if (type == 'new_message' || type == 'new_offer' || type == 'offer_responded') {
      if (refId != null) {
        // Extraer nombre del remitente desde el body/title de la notificación
        String otherName = 'Usuario';
        final body = notification.body ?? '';
        final title = notification.title;
        if (type == 'new_offer' || type == 'offer_responded') {
          // body: "Juan ha realizado una contraoferta..." o "Juan aceptó tu contraoferta..."
          final namePart = body.split(RegExp(r'\s+(ha realizado|aceptó|rechazó)\s+'));
          if (namePart.length >= 2) {
            otherName = namePart[0].trim();
          }
        } else if (type == 'new_message') {
          // title: "Nuevo mensaje de Juan"
          final namePart = title.split(' de ');
          if (namePart.length >= 2) {
            otherName = namePart.sublist(1).join(' de ').trim();
          }
        }
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => SharedChatScreen(
            conversationId: refId,
            otherUserName: otherName,
          ),
        ));
      }
    } else if (type == 'new_application') {
      if (refId != null) {
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => OffersReceivedScreen(serviceId: refId),
        ));
      }
    } else if (type == 'job_accepted' || 
               type == 'job_waiting_confirmation' || 
               type == 'job_completed' || 
               type == 'job_cancelled' ||
               type == 'payment_deadline' ||
               type == 'confirmation_deadline') {
                  
      ref.read(workerNavProvider.notifier).state = 1;
      ref.read(clientNavProvider.notifier).state = 3;
      
      if (type == 'job_accepted' || type == 'job_waiting_confirmation' || type == 'confirmation_deadline') {
         ref.read(myRequestsTabProvider.notifier).state = 1;
      } else if (type == 'job_completed' || type == 'job_cancelled') {
         ref.read(myRequestsTabProvider.notifier).state = 2;
      }

      if (type == 'job_waiting_confirmation' || type == 'confirmation_deadline') {
        Navigator.pushNamedAndRemoveUntil(context, '/client_home', (route) => false);
      } else {
        Navigator.pushNamedAndRemoveUntil(context, '/worker_home', (route) => false);
      }
    } else if (type == 'payment_released' || type == 'auto_released' || type == 'payment_held') {
      Navigator.pushNamedAndRemoveUntil(context, '/worker_home', (route) => false);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const WalletScreen(),
        ),
      );
    } else if (type == 'payment_expired') {
      Navigator.pushNamedAndRemoveUntil(context, '/client_home', (route) => false);
    }
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'new_application': return Icons.person_add;
      case 'job_accepted': return Icons.check_circle;
      case 'job_waiting_confirmation': return Icons.hourglass_bottom;
      case 'job_completed': return Icons.verified;
      case 'job_cancelled': return Icons.cancel;
      case 'new_message': return Icons.chat_bubble;
      case 'new_offer': return Icons.local_offer;
      case 'offer_responded': return Icons.handshake;
      case 'payment_released': return Icons.account_balance_wallet;
      case 'payment_held': return Icons.lock;
      case 'payment_deadline': return Icons.timer;
      case 'confirmation_deadline': return Icons.hourglass_top;
      case 'payment_expired': return Icons.timer_off;
      case 'auto_released': return Icons.rocket_launch;
      default: return Icons.notifications;
    }
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'new_application': return Colors.blue;
      case 'job_accepted': return Colors.green;
      case 'job_waiting_confirmation': return Colors.orange;
      case 'job_completed': return Colors.teal;
      case 'job_cancelled': return Colors.red;
      case 'new_message': return Colors.indigo;
      case 'new_offer': return Colors.amber;
      case 'offer_responded': return Colors.deepPurple;
      case 'payment_released': return const Color(0xFF7F13EC);
      case 'payment_held': return const Color(0xFF4F46E5);
      case 'payment_deadline': return Colors.red;
      case 'confirmation_deadline': return Colors.orange;
      case 'payment_expired': return Colors.red.shade700;
      case 'auto_released': return const Color(0xFF10B981);
      default: return Colors.grey;
    }
  }

  String _formatBody(String body) {
    final regex = RegExp(r'\$(\d+)\.0{1,2}\b');
    return body.replaceAllMapped(regex, (match) => '\$${match.group(1)}');
  }
}
