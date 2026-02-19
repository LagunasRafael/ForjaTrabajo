import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/nav_index_provider.dart';

// 👇 AQUÍ IMPORTAS TU PANTALLA REAL
import '../client/home_client_screen.dart'; // O el nombre exacto que le pusiste

// (Si aún no tienes creadas estas otras 4 pantallas, créalas vacías por ahora para que no marque error)
import '../client/my_requests_screen.dart';
import '../shared/chat_list_screen.dart';
import '../shared/notifications_screen.dart';
import '../client/client_profile_screen.dart';

class ClientMainLayout extends ConsumerWidget {
  const ClientMainLayout({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(clientNavProvider);

    // 👇 LA LISTA DE TUS 5 PANTALLAS (El índice 0 es tu Home)
    final List<Widget> screens = [
      const HomeClientScreen(), // <--- TU PANTALLA APARECE AQUÍ
      const MyRequestsScreen(),
      const ChatListScreen(),
      const NotificationsScreen(),
      const ClientProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          ref.read(clientNavProvider.notifier).state = index;
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Inicio'),
          NavigationDestination(icon: Icon(Icons.list_alt_outlined), selectedIcon: Icon(Icons.list_alt), label: 'Solicitudes'),
          NavigationDestination(icon: Icon(Icons.chat_bubble_outline), selectedIcon: Icon(Icons.chat_bubble), label: 'Chats'),
          NavigationDestination(icon: Icon(Icons.notifications_outlined), selectedIcon: Icon(Icons.notifications), label: 'Avisos'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }
}