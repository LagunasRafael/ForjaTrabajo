import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forja_trabajo/features/services/presentation/screens/worker/marketplace_screen.dart';
import 'package:forja_trabajo/features/services/presentation/providers/nav_providers.dart';
import '../worker/my_jobs_screen.dart';
import 'package:forja_trabajo/features/chat/presentation/screens/chat_list_screen.dart';
import 'package:forja_trabajo/features/services/presentation/screens/layout/client_main_layout.dart';
import '../shared/notifications_screen.dart';
import '../worker/worker_profile_screen.dart'; // O ClientProfileScreen si reúsas

class WorkerMainLayout extends ConsumerWidget {
  const WorkerMainLayout({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(workerNavProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final List<Widget> screens = [
      const MarketplaceScreen(), // 0
      const MyJobsScreen(), // 1
      ChatListScreen(), // 2
      const NotificationsScreen(), // 3
      const WorkerProfileScreen(), // 4
    ];

    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: screens,
      ),

      // 🚫 SIN BOTÓN FLOTANTE
      // 🚫 SIN RECORTE

      // ✅ BARRA SÓLIDA ESTÁNDAR
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          ref.read(workerNavProvider.notifier).state = index;
        },
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        elevation: 3,
        indicatorColor: isDark
            ? const Color(0xFF4F46E5).withOpacity(0.2)
            : const Color(0xFF1E1B4B).withOpacity(0.1),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.search),
            selectedIcon: Icon(Icons.search, color: Color(0xFF1E1B4B)),
            label: 'Explorar',
          ),
          NavigationDestination(
            icon: Icon(Icons.work_history_outlined),
            selectedIcon: Icon(Icons.work_history, color: Color(0xFF1E1B4B)),
            label: 'Mis Tareas',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble, color: Color(0xFF1E1B4B)),
            label: 'Chats',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_outlined),
            selectedIcon: Icon(Icons.notifications, color: Color(0xFF1E1B4B)),
            label: 'Avisos',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: Color(0xFF1E1B4B)),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
