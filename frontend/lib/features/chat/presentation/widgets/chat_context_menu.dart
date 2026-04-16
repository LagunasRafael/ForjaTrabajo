import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/chat_list_provider.dart';
import '../../domain/entities/chat_summary_entity.dart';

class ChatContextMenu {
  static Future<void> show(BuildContext context, WidgetRef ref, {required Offset position, required ChatSummaryEntity chat}) async {
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;

    // 🧠 Detectamos si el chat actual está archivado
    final isArchived = chat.isArchived;

    final value = await showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(
        position & const Size(40, 40), 
        Offset.zero & overlay.size,
      ),
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), 
      items: [
        // 🟢 BOTÓN DINÁMICO: Archivar / Recuperar
        PopupMenuItem(
          value: isArchived ? 'unarchive' : 'archive',
          child: Row(
            children: [
              Icon(isArchived ? Icons.unarchive_outlined : Icons.archive_outlined, size: 22, color: Colors.black87), 
              const SizedBox(width: 12), 
              Text(isArchived ? 'Recuperar chat' : 'Archivar conversación')
            ]
          ),
        ),
        const PopupMenuItem(
          value: 'report',
          child: Row(
            children: [
              Icon(Icons.flag_outlined, size: 22, color: Colors.orange), 
              SizedBox(width: 12), 
              Text('Reportar usuario')
            ]
          ),
        ),
        const PopupMenuDivider(), 
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline, size: 22, color: Colors.red), 
              SizedBox(width: 12), 
              Text('Borrar chat', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))
            ]
          ),
        ),
      ],
    );

    if (value != null && context.mounted) {
      if (value == 'archive' || value == 'unarchive') {
        // Ejecutamos la función de archivar o desarchivar
        ref.read(chatListProvider.notifier).toggleArchiveStatus(chat.id, value == 'archive');
      } else if (value == 'delete') {
        // Confirmación antes de eliminar
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Eliminar chat'),
            content: const Text('¿Deseas eliminar esta conversación para ti?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
              TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Eliminar', style: TextStyle(color: Colors.red))),
            ],
          ),
        );
        if (confirm == true && context.mounted) {
          ref.read(chatListProvider.notifier).deleteChat(chat.id);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Chat eliminado'),
              behavior: SnackBarBehavior.floating, 
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );
        }
        return; // Salir para no mostrar el snackbar genérico debajo
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            value == 'archive' ? 'Conversación archivada' :
            value == 'unarchive' ? 'Conversación movida a Activos' : 'Usuario reportado'
          ),
          behavior: SnackBarBehavior.floating, 
          backgroundColor: const Color(0xFF4F46E5),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}