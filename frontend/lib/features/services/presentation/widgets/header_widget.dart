import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forja_trabajo/features/auth/presentation/providers/auth_provider.dart';

class Header extends ConsumerWidget {
  const Header({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final userName = authState.user?.fullName ?? 'Usuario';
    final userImageUrl = authState.user?.profilePictureUrl;

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
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, overflow: TextOverflow.ellipsis), 
                maxLines: 1
              )
            ]
          ),
        ),
        const SizedBox(width: 12),
        CircleAvatar(
          radius: 26,
          backgroundColor: Colors.indigo.shade50,
          backgroundImage: (userImageUrl != null && userImageUrl.isNotEmpty) 
              ? NetworkImage(userImageUrl) 
              : null,
          child: (userImageUrl == null || userImageUrl.isEmpty)
              ? const Icon(Icons.person, color: Colors.indigo, size: 28)
              : null,
        ),
      ]
    );
  }
}