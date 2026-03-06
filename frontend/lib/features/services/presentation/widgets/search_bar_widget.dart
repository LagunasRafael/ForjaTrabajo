import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// 👇 Asegúrate de que esta ruta apunte a donde tienes tu searchQueryProvider
import 'package:forja_trabajo/features/services/presentation/providers/service_list_provider.dart'; 

class SearchBarWidget extends ConsumerWidget { // 🚀 Nombre correcto y sin "_"
  const SearchBarWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(16)),
      child: TextField(
        onChanged: (value) => ref.read(searchQueryProvider.notifier).state = value,
        decoration: const InputDecoration(
          hintText: "Buscar trabajos...", 
          prefixIcon: Icon(Icons.search, color: Colors.grey), 
          border: InputBorder.none
        ),
      ),
    );
  }
}