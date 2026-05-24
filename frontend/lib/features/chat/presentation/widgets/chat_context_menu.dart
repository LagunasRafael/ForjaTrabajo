import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/chat_list_provider.dart';
import '../../domain/entities/chat_summary_entity.dart';
import 'package:forja_trabajo/core/network/api_client.dart';


class ChatContextMenu {
  static Future<void> show(BuildContext context, WidgetRef ref, {required Offset position, required ChatSummaryEntity chat}) async {
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;

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
        ref.read(chatListProvider.notifier).toggleArchiveStatus(chat.id, value == 'archive');
      } else if (value == 'delete') {
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
        return;
      } else if (value == 'report') {
        _showReportDialog(context, chat);
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            value == 'archive' ? 'Conversacion archivada' :
            value == 'unarchive' ? 'Conversacion movida a Activos' : ''
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF4F46E5),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  static Future<void> _showReportDialog(BuildContext context, ChatSummaryEntity chat) async {
    final reasonController = TextEditingController();
    String selectedReason = 'inappropriate_content';

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.flag, color: Colors.orange),
              SizedBox(width: 8),
              Text('Reportar usuario'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('¿Por qué quieres reportar a este usuario?'),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedReason,
                  decoration: const InputDecoration(
                    labelText: 'Motivo',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'spam', child: Text('Spam')),
                    DropdownMenuItem(value: 'inappropriate_content', child: Text('Contenido inapropiado')),
                    DropdownMenuItem(value: 'scam', child: Text('Estafa')),
                    DropdownMenuItem(value: 'harassment', child: Text('Acoso')),
                    DropdownMenuItem(value: 'fake_profile', child: Text('Perfil falso')),
                    DropdownMenuItem(value: 'other', child: Text('Otro')),
                  ],
                  onChanged: (v) {
                    if (v != null) setDialogState(() => selectedReason = v);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: reasonController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Describe lo sucedido (opcional)...',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Enviar reporte', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );

    if (result == true && context.mounted) {
      try {
        final otherUserId = chat.otherUserId;
        if (otherUserId == null || otherUserId.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No se pudo identificar al usuario'), backgroundColor: Colors.red),
          );
          return;
        }

        await ApiClient().reportUser(
          reportedUserId: otherUserId,
          reason: selectedReason,
          description: reasonController.text.isNotEmpty ? reasonController.text : null,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reporte enviado. Un administrador lo revisará.'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}