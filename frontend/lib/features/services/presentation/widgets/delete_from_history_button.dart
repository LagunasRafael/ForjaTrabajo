import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:forja_trabajo/features/services/presentation/providers/service_repository_provider.dart';

class DeleteFromHistoryButton extends ConsumerWidget {
  final String serviceId;
  final VoidCallback onDeleted;

  const DeleteFromHistoryButton({
    super.key,
    required this.serviceId,
    required this.onDeleted,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.red.shade200),
        borderRadius: BorderRadius.circular(10),
      ),
      child: IconButton(
        icon: const Icon(Icons.delete_outline, color: Colors.red, size: 24),
        onPressed: () => _confirmDelete(context, ref),
        tooltip: 'Eliminar de mi historial',
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar del historial'),
        content: const Text('¿Eliminar este servicio de tu historial?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Eliminar', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      if (token.isEmpty) return;
      final success = await ref.read(serviceRepositoryProvider).hideFromHistory(serviceId, token);
      if (success && context.mounted) {
        onDeleted();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Eliminado del historial'), behavior: SnackBarBehavior.floating),
        );
      }
    }
  }
}
