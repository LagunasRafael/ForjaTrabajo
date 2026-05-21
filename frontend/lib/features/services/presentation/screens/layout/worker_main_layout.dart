import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forja_trabajo/features/services/presentation/screens/worker/marketplace_screen.dart';
import 'package:forja_trabajo/features/services/presentation/providers/nav_providers.dart';
import 'package:forja_trabajo/features/chat/presentation/providers/unread_count_provider.dart';
import 'package:forja_trabajo/features/notifications/presentation/providers/notification_provider.dart';
import '../worker/my_jobs_screen.dart';
import 'package:forja_trabajo/features/chat/presentation/screens/chat_list_screen.dart';
import 'package:forja_trabajo/features/notifications/presentation/screens/notifications_screen.dart';
import '../worker/worker_profile_screen.dart';

class WorkerMainLayout extends ConsumerWidget {
  const WorkerMainLayout({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(workerNavProvider);
    final unreadChatCount = ref.watch(unreadCountProvider);
    final unreadNotifCount = ref.watch(unreadNotificationCountProvider);
    final theme = Theme.of(context);

    final List<Widget> screens = [
      const MarketplaceScreen(), // 0
      const MyJobsScreen(), // 1
      const ChatListScreen(), // 2
      const WorkerProfileScreen(), // 3
    ];

    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: screens,
      ),

      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          ref.read(workerNavProvider.notifier).state = index;
        },
        backgroundColor: theme.colorScheme.surface,
        elevation: 3,
        indicatorColor: theme.colorScheme.primary.withOpacity(0.15),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.search),
            selectedIcon: Icon(Icons.search, color: Color(0xFF1E1B4B)),
            label: 'Explorar',
          ),
          const NavigationDestination(
            icon: Icon(Icons.work_history_outlined),
            selectedIcon: Icon(Icons.work_history, color: Color(0xFF1E1B4B)),
            label: 'Mis Trabajos',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: unreadChatCount > 0,
              label: Text(
                unreadChatCount > 9 ? '9+' : '$unreadChatCount',
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
              backgroundColor: const Color(0xFFEF4444),
              child: const Icon(Icons.chat_bubble_outline),
            ),
            selectedIcon: Badge(
              isLabelVisible: unreadChatCount > 0,
              label: Text(
                unreadChatCount > 9 ? '9+' : '$unreadChatCount',
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
              backgroundColor: const Color(0xFFEF4444),
              child: const Icon(Icons.chat_bubble, color: Color(0xFF1E1B4B)),
            ),
            label: 'Mensajes',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: Color(0xFF1E1B4B)),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
