import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forja_trabajo/features/chat/presentation/screens/shared_chat_screen.dart';
import 'package:forja_trabajo/features/services/presentation/screens/client/offers_received_screen.dart';
import 'package:forja_trabajo/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:forja_trabajo/features/services/presentation/screens/client/my_requests_screen.dart';
import 'package:forja_trabajo/features/services/presentation/screens/worker/my_jobs_screen.dart';
import 'package:forja_trabajo/features/chat/presentation/providers/chat_list_provider.dart';
import 'package:forja_trabajo/features/services/presentation/providers/nav_providers.dart';
import 'package:forja_trabajo/features/payments/presentation/screens/wallet_screen.dart';

IconData iconForNotificationType(String type) {
  switch (type) {
    case 'new_message':
      return Icons.chat_bubble_rounded;
    case 'new_offer':
      return Icons.local_offer_rounded;
    case 'offer_responded':
      return Icons.handshake_rounded;
    case 'new_application':
      return Icons.person_add_rounded;
    case 'job_accepted':
    case 'in_progress':
      return Icons.check_circle_rounded;
    case 'job_waiting_confirmation':
      return Icons.hourglass_bottom_rounded;
    case 'job_completed':
      return Icons.verified_rounded;
    case 'job_cancelled':
      return Icons.cancel_rounded;
    case 'payment_deadline':
      return Icons.timer_rounded;
    case 'confirmation_deadline':
      return Icons.schedule_rounded;
    case 'payment_expired':
      return Icons.timer_off_rounded;
    case 'payment_held':
    case 'payment_released':
      return Icons.payments_rounded;
    case 'payment_refunded':
      return Icons.currency_exchange_rounded;
    case 'auto_released':
      return Icons.autorenew_rounded;
    case 'dispute_opened':
      return Icons.gavel_rounded;
    case 'dispute_resolved':
      return Icons.checklist_rounded;
    default:
      return Icons.notifications_rounded;
  }
}

Color colorForNotificationType(String type) {
  switch (type) {
    case 'new_application':
      return Colors.blue;
    case 'job_accepted':
      return Colors.green;
    case 'job_waiting_confirmation':
      return Colors.orange;
    case 'job_completed':
      return Colors.teal;
    case 'job_cancelled':
      return Colors.red;
    case 'new_message':
      return Colors.indigo;
    case 'new_offer':
      return Colors.amber;
    case 'offer_responded':
      return Colors.deepPurple;
    case 'payment_released':
      return const Color(0xFF7F13EC);
    case 'payment_held':
      return const Color(0xFF4F46E5);
    case 'payment_deadline':
      return Colors.red;
    case 'confirmation_deadline':
      return Colors.orange;
    case 'payment_expired':
      return Colors.red.shade700;
    case 'auto_released':
      return const Color(0xFF10B981);
    default:
      return Colors.grey;
  }
}

void navigateFromNotification({
  required BuildContext context,
  required String type,
  String? conversationId,
  String? serviceId,
  String? senderName,
  String? targetRole,
  ProviderContainer? container,
  bool clearStack = false,
  bool navigateToWallet = false,
}) {
  final navigator = Navigator.of(context);

  // --- Chat notification types ---
  if (type == 'new_message' || type == 'new_offer' || type == 'admin_message' || type == 'dispute_opened' || type == 'offer_responded') {
    final id = conversationId;
    if (id == null) return;
    if (container != null && (type == 'new_message' || type == 'new_offer' || type == 'admin_message' || type == 'dispute_opened')) {
      container.read(chatListProvider.notifier).loadRealChats();
    }
    navigator.push(MaterialPageRoute(
      builder: (_) => SharedChatScreen(
        conversationId: id,
        otherUserName: senderName ?? 'Chat Soporte',
      ),
    ));
    return;
  }

  // --- Application notification ---
  if (type == 'new_application') {
    if (serviceId != null) {
      navigator.push(MaterialPageRoute(builder: (_) => OffersReceivedScreen(serviceId: serviceId)));
    } else {
      container?.read(clientNavProvider.notifier).state = 3;
      container?.read(myRequestsTabProvider.notifier).state = 0;
      navigator.push(MaterialPageRoute(builder: (_) => const MyRequestsScreen(initialIndex: 0)));
    }
    return;
  }

  // --- Wallet navigation (notification_card behavior) ---
  if (navigateToWallet && (type == 'payment_released' || type == 'auto_released' || type == 'payment_held')) {
    navigator.pushNamedAndRemoveUntil('/worker_home', (route) => false);
    navigator.push(MaterialPageRoute(builder: (_) => const WalletScreen()));
    return;
  }

  // --- payment_expired with clearStack (notification_card behavior) ---
  if (clearStack && type == 'payment_expired') {
    navigator.pushNamedAndRemoveUntil('/client_home', (route) => false);
    return;
  }

  // --- ClearStack path for job types (notification_card behavior) ---
  if (clearStack) {
    if (type == 'job_accepted' || type == 'job_waiting_confirmation' || type == 'job_completed' || type == 'job_cancelled' || type == 'payment_deadline' || type == 'confirmation_deadline') {
      container?.read(workerNavProvider.notifier).state = 1;
      container?.read(clientNavProvider.notifier).state = 3;
      if (type == 'job_accepted' || type == 'job_waiting_confirmation' || type == 'confirmation_deadline') {
        container?.read(myRequestsTabProvider.notifier).state = 1;
      } else if (type == 'job_completed' || type == 'job_cancelled') {
        container?.read(myRequestsTabProvider.notifier).state = 2;
      }
      if (type == 'job_waiting_confirmation' || type == 'confirmation_deadline') {
        navigator.pushNamedAndRemoveUntil('/client_home', (route) => false);
      } else {
        navigator.pushNamedAndRemoveUntil('/worker_home', (route) => false);
      }
    }
    return;
  }

  // --- Push path (notification_service behavior) ---

  if (type == 'job_accepted' || type == 'in_progress') {
    container?.read(workerNavProvider.notifier).state = 1;
    container?.read(workerJobsTabProvider.notifier).state = 1;
    navigator.push(MaterialPageRoute(builder: (_) => const MyJobsScreen(initialIndex: 1)));
    return;
  }

  if (type == 'job_completed') {
    container?.read(workerNavProvider.notifier).state = 1;
    container?.read(workerJobsTabProvider.notifier).state = 2;
    navigator.push(MaterialPageRoute(builder: (_) => const MyJobsScreen(initialIndex: 2)));
    return;
  }

  if (type == 'job_waiting_confirmation' || type == 'payment_deadline') {
    container?.read(clientNavProvider.notifier).state = 3;
    container?.read(myRequestsTabProvider.notifier).state = 1;
    navigator.push(MaterialPageRoute(builder: (_) => const MyRequestsScreen(initialIndex: 1)));
    return;
  }

  if (type == 'confirmation_deadline') {
    container?.read(workerNavProvider.notifier).state = 1;
    container?.read(workerJobsTabProvider.notifier).state = 1;
    navigator.push(MaterialPageRoute(builder: (_) => const MyJobsScreen(initialIndex: 1)));
    return;
  }

  if (type == 'job_cancelled' || type == 'payment_expired') {
    if (targetRole == 'client') {
      container?.read(clientNavProvider.notifier).state = 3;
      container?.read(myRequestsTabProvider.notifier).state = 0;
      navigator.push(MaterialPageRoute(builder: (_) => const MyRequestsScreen(initialIndex: 0)));
    } else {
      container?.read(workerNavProvider.notifier).state = 1;
      container?.read(workerJobsTabProvider.notifier).state = 2;
      navigator.push(MaterialPageRoute(builder: (_) => const MyJobsScreen(initialIndex: 2)));
    }
    return;
  }

  if (type == 'payment_held' || type == 'payment_released') {
    if (targetRole == 'worker') {
      container?.read(workerNavProvider.notifier).state = 1;
      container?.read(workerJobsTabProvider.notifier).state = 1;
      navigator.push(MaterialPageRoute(builder: (_) => const MyJobsScreen(initialIndex: 1)));
    } else {
      container?.read(clientNavProvider.notifier).state = 3;
      container?.read(myRequestsTabProvider.notifier).state = 1;
      navigator.push(MaterialPageRoute(builder: (_) => const MyRequestsScreen(initialIndex: 1)));
    }
    return;
  }

  if (type == 'auto_released') {
    if (targetRole == 'worker') {
      container?.read(workerNavProvider.notifier).state = 1;
      container?.read(workerJobsTabProvider.notifier).state = 2;
      navigator.push(MaterialPageRoute(builder: (_) => const MyJobsScreen(initialIndex: 2)));
    } else {
      container?.read(clientNavProvider.notifier).state = 3;
      container?.read(myRequestsTabProvider.notifier).state = 2;
      navigator.push(MaterialPageRoute(builder: (_) => const MyRequestsScreen(initialIndex: 2)));
    }
    return;
  }

  if (type == 'payment_refunded') {
    if (targetRole == 'client') {
      container?.read(clientNavProvider.notifier).state = 3;
      container?.read(myRequestsTabProvider.notifier).state = 2;
      navigator.push(MaterialPageRoute(builder: (_) => const MyRequestsScreen(initialIndex: 2)));
    } else {
      container?.read(workerNavProvider.notifier).state = 1;
      container?.read(workerJobsTabProvider.notifier).state = 2;
      navigator.push(MaterialPageRoute(builder: (_) => const MyJobsScreen(initialIndex: 2)));
    }
    return;
  }

  // Default fallback
  navigator.push(MaterialPageRoute(builder: (_) => const NotificationsScreen()));
}
