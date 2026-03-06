import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// 👇 Importamos el provider que acabamos de crear
import 'package:forja_trabajo/features/services/presentation/providers/nav_providers.dart';

// Pantallas del Cliente
import '../client/home_client_screen.dart';
import '../client/my_requests_screen.dart';
import '../shared/chat_list_screen.dart';
import '../shared/notifications_screen.dart'; // (Opcional si la usas)
import '../client/client_profile_screen.dart';
import '../client/create_services_screen.dart';

class ClientMainLayout extends ConsumerWidget {
  const ClientMainLayout({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(clientNavProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final List<Widget> screens = [
      const HomeClientScreen(), // 0
      const ChatListScreen(), // 1
      const SizedBox(), // 2 (Espacio vacío para el botón flotante)
      const MyRequestsScreen(), // 3
      const ClientProfileScreen(), // 4
    ];

    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: screens,
      ),

      // ✅ BOTÓN FLOTANTE (Solo para Cliente)
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF1E1B4B),
        elevation: 6,
        shape: const CircleBorder(),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const CreateServiceScreen()),
          );
        },
        child: const Icon(Icons.add, color: Colors.white, size: 32),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // ✅ BARRA CON RECORTE (Notch)
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        elevation: 10,
        shadowColor: Colors.black.withOpacity(0.4),
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              Expanded(
                  child: _buildNavItem(
                      Icons.home_filled, 'Inicio', 0, ref, currentIndex)),
              Expanded(
                  child: _buildNavItem(Icons.chat_bubble_rounded, 'Mensajes', 1,
                      ref, currentIndex)),

              const SizedBox(width: 48), // 👈 El hueco para el botón

              Expanded(
                  child: _buildNavItem(
                      Icons.work, 'Mis Trabajos', 3, ref, currentIndex)),
              Expanded(
                  child: _buildNavItem(
                      Icons.person, 'Perfil', 4, ref, currentIndex)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
      IconData icon, String label, int index, WidgetRef ref, int currentIndex) {
    final isSelected = currentIndex == index;
    final color = isSelected ? const Color(0xFF1E1B4B) : Colors.grey.shade400;

    return InkWell(
      onTap: () => ref.read(clientNavProvider.notifier).state = index,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500))
        ],
      ),
    );
  }
}
