import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forja_trabajo/features/services/presentation/screens/admin/admin_dashboard_screen.dart';
import 'package:forja_trabajo/features/services/presentation/screens/admin/admin_profile_screen.dart';
import 'package:forja_trabajo/features/services/presentation/screens/admin/manage_categories_screen.dart';

// 👇 1. CREAMOS EL PROVIDER AQUÍ MISMO PARA NO DEPENDER DE OTRO ARCHIVO
final adminNavProvider = StateProvider<int>((ref) => 0);

// 👇 2. IMPORTAS TUS 3 PANTALLAS DE ADMIN (Ajusta los ../ según tus carpetas)

class AdminMainLayout extends ConsumerWidget {
  const AdminMainLayout({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Escuchamos en qué pestaña estamos
    final currentIndex = ref.watch(adminNavProvider);

    // 👇 LA LISTA DE TUS PANTALLAS DE ADMIN
    final List<Widget> screens = [
      const AdminDashboardScreen(),   // Índice 0: Tu panel de estadísticas
      const ManageCategoriesScreen(), // Índice 1: Donde creamos categorías
      const AdminProfileScreen(),     // Índice 2: Tu perfil con el botón de salir
    ];

    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          ref.read(adminNavProvider.notifier).state = index;
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined), 
            selectedIcon: Icon(Icons.dashboard), 
            label: 'Panel'
          ),
          NavigationDestination(
            icon: Icon(Icons.category_outlined), 
            selectedIcon: Icon(Icons.category), 
            label: 'Categorías'
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline), 
            selectedIcon: Icon(Icons.person), 
            label: 'Perfil'
          ),
        ],
      ),
    );
  }
}