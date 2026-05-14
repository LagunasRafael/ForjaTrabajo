import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forja_trabajo/features/auth/presentation/providers/auth_provider.dart';
import 'package:forja_trabajo/features/notifications/presentation/providers/notification_provider.dart';
import 'package:forja_trabajo/features/notifications/presentation/screens/notifications_screen.dart';

class HeaderWidget extends ConsumerWidget {
  const HeaderWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final userName = authState.user?.fullName ?? 'Usuario';
    final userImageUrl = authState.user?.profilePictureUrl;
    final unreadNotifCount = ref.watch(unreadNotificationCountProvider);
    
    // 🎨 Detección del tema (Modo Claro / Oscuro)
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween, 
      children: [
        Expanded( 
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, 
            children: [
              const Text("Bienvenido de nuevo", style: TextStyle(color: Colors.grey, fontSize: 14)), 
              Text(
                "Hola, $userName", 
                style: TextStyle(
                  fontSize: 26, 
                  fontWeight: FontWeight.w800, 
                  overflow: TextOverflow.ellipsis,
                  color: isDark ? Colors.white : Colors.black87 // 🎨 Cambio de color
                ), 
                maxLines: 1
              )
            ]
          ),
        ),
        const SizedBox(width: 8),
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF334155) : Colors.grey.shade100,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Badge(
              isLabelVisible: unreadNotifCount > 0,
              label: Text(
                unreadNotifCount > 9 ? '9+' : '$unreadNotifCount',
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
              backgroundColor: const Color(0xFFEF4444),
              child: Icon(Icons.notifications_outlined, color: isDark ? Colors.white70 : Colors.black87),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NotificationsScreen()),
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        CircleAvatar(
          radius: 26,
          backgroundColor: isDark ? const Color(0xFF334155) : Colors.indigo.shade50, // 🎨 Fondo adaptable
          backgroundImage: (userImageUrl != null && userImageUrl.isNotEmpty) 
              ? NetworkImage(userImageUrl) 
              : null,
          child: (userImageUrl == null || userImageUrl.isEmpty)
              ? Icon(Icons.person, color: isDark ? Colors.white70 : Colors.indigo, size: 28)
              : null,
        ),
      ]
    );
  }
}