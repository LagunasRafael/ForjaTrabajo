import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/screens/profile_screen.dart';
import 'home_client_screen.dart';

class MainClientScreen extends StatefulWidget {
  const MainClientScreen({super.key});

  @override
  State<MainClientScreen> createState() => _MainClientScreenState();
}

class _MainClientScreenState extends State<MainClientScreen> {
  int _currentIndex = 0;

  // 📦 Aquí metemos las pantallas que van a ser pestañas
  final List<Widget> _screens = [
    const HomeClientScreen(), // Índice 0: Inicio
    const Center(child: Text('Mis Trabajos (Próximamente)')), // Índice 1: Historial (Placeholder)
    const ProfileScreen(), // Índice 2: Perfil
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      // 🔄 IndexedStack guarda el estado de las pantallas para que no se recarguen al cambiar de pestaña
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            backgroundColor: Colors.white,
            selectedItemColor: AppTheme.primaryColor,
            unselectedItemColor: Colors.grey.shade400,
            showSelectedLabels: true,
            showUnselectedLabels: true,
            type: BottomNavigationBarType.fixed,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
            elevation: 0,
            items: const [
              BottomNavigationBarItem(
                icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(LucideIcons.home)),
                activeIcon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(LucideIcons.home, size: 26)),
                label: 'Inicio',
              ),
              BottomNavigationBarItem(
                icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(LucideIcons.briefcase)),
                activeIcon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(LucideIcons.briefcase, size: 26)),
                label: 'Trabajos',
              ),
              BottomNavigationBarItem(
                icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(LucideIcons.user)),
                activeIcon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(LucideIcons.userCircle, size: 26)),
                label: 'Perfil',
              ),
            ],
          ),
        ),
      ),
    );
  }
}