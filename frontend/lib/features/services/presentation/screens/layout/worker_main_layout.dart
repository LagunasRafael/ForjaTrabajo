import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/nav_index_provider.dart';

// 👇 TUS PANTALLAS (Usando tu nombre original MyJobsScreen)
import '../worker/marketplace_screen.dart'; 
import '../worker/my_jobs_screen.dart';       // <--- AQUÍ ESTÁ EL CAMBIO
import '../shared/chat_list_screen.dart';
import '../shared/notifications_screen.dart';
import '../worker/worker_profile_screen.dart';

class WorkerMainLayout extends ConsumerWidget {
  const WorkerMainLayout({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(workerNavProvider);

    // 👇 LA LISTA DE TUS 5 PANTALLAS
    final List<Widget> screens = [
      const MarketplaceScreen(),
      const MyJobsScreen(),                   // <--- AQUÍ ESTÁ EL CAMBIO
      const ChatListScreen(),
      const NotificationsScreen(),
      const WorkerProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: currentIndex, children: screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) => ref.read(workerNavProvider.notifier).state = index,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.search), selectedIcon: Icon(Icons.search), label: 'Explorar'),
          NavigationDestination(icon: Icon(Icons.work_history_outlined), selectedIcon: Icon(Icons.work_history), label: 'Mis Trabajos'), // <--- Actualicé el texto aquí
          NavigationDestination(icon: Icon(Icons.chat_bubble_outline), selectedIcon: Icon(Icons.chat_bubble), label: 'Chats'),
          NavigationDestination(icon: Icon(Icons.notifications_outlined), selectedIcon: Icon(Icons.notifications), label: 'Avisos'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }
}