import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/nav_index_provider.dart';

import '../client/home_client_screen.dart'; 
import '../client/my_requests_screen.dart';
import '../shared/chat_list_screen.dart';
import '../shared/notifications_screen.dart';
import '../client/client_profile_screen.dart';
// 👇 Importamos la pantalla de crear servicio
import '../client/create_services_screen.dart'; 

class ClientMainLayout extends ConsumerWidget {
  const ClientMainLayout({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(clientNavProvider);

    final List<Widget> screens = [
      const HomeClientScreen(),
      const ChatListScreen(), // Índice 1: Mensajes (como en la imagen)
      const SizedBox(), // Índice 2: VACÍO (Aquí va el botón de en medio, nunca se muestra esta pantalla)
      const MyRequestsScreen(), // Índice 3: Mis Trabajos
      const ClientProfileScreen(), // Índice 4: Perfil
    ];

    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: screens,
      ),
      // 👇 EL BOTÓN FLOTANTE GIGANTE EN MEDIO
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF1E1B4B), // Azul fuerte de tu diseño
        elevation: 8,
        shape: const CircleBorder(),
        onPressed: () {
          // Navega a la pantalla de crear servicio
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateServiceScreen()),
          );
        },
        child: const Icon(Icons.add, color: Colors.white, size: 32),
      ),
      // 👇 POSICIÓN DEL BOTÓN FLOTANTE
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      
      // 👇 LA BARRA CON EL RECORTE
      // 👇 LA BARRA CON EL RECORTE
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        color: Colors.white,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              _buildNavItem(icon: Icons.home_filled, label: 'Inicio', index: 0, ref: ref, currentIndex: currentIndex),
              _buildNavItem(icon: Icons.chat_bubble_rounded, label: 'Mensajes', index: 1, ref: ref, currentIndex: currentIndex),
              const SizedBox(width: 48), // Espacio para el botón flotante
              _buildNavItem(icon: Icons.work, label: 'Mis Trabajos', index: 3, ref: ref, currentIndex: currentIndex),
              _buildNavItem(icon: Icons.person, label: 'Perfil', index: 4, ref: ref, currentIndex: currentIndex),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({required IconData icon, required String label, required int index, required WidgetRef ref, required int currentIndex}) {
    final isSelected = currentIndex == index;
    final color = isSelected ? const Color(0xFF1E1B4B) : Colors.grey.shade400;

    return MaterialButton(
      minWidth: 40,
      onPressed: () {
        ref.read(clientNavProvider.notifier).state = index;
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(color: color, fontSize: 10, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
          )
        ],
      ),
    );
  }
}