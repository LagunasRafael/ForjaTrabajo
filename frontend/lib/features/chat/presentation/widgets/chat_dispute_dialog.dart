import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forja_trabajo/features/chat/presentation/providers/chat_provider.dart';

Future<void> showDisputeDialog(
  BuildContext parentContext,
  WidgetRef ref,
  String conversationId,
) async {
  final reasonController = TextEditingController();

  await showDialog(
    context: parentContext,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.gavel, color: Colors.red),
            SizedBox(width: 8),
            Text('Abrir Disputa', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Describe el motivo de la disputa. Un administrador revisará el caso.'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Ej. El trabajador no completó el servicio...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) return;

              final scaffoldMessenger = ScaffoldMessenger.of(parentContext);
              Navigator.pop(dialogContext);

              try {
                await ref
                    .read(chatProvider(conversationId).notifier)
                    .openDispute(reason);

                if (parentContext.mounted) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: const Text(
                        'Disputa abierta. Un administrador se pondrá en contacto pronto.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Color(0xFF4F46E5)),
                      ),
                      backgroundColor: const Color(0xFFF0F0F0).withOpacity(1),
                      behavior: SnackBarBehavior.floating,
                      margin: EdgeInsets.only(
                        bottom: (MediaQuery.of(parentContext).size.height - 835).clamp(0, double.infinity),
                        left: 24,
                        right: 24,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              } catch (e) {
                if (parentContext.mounted) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: const Text(
                        'Error al abrir la disputa. Intenta de nuevo.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Color(0xFF4F46E5)),
                      ),
                      backgroundColor: const Color(0xFFF0F0F0).withOpacity(1),
                      behavior: SnackBarBehavior.floating,
                      margin: EdgeInsets.only(
                        bottom: (MediaQuery.of(parentContext).size.height - 835).clamp(0, double.infinity),
                        left: 24,
                        right: 24,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              }
            },
            child: const Text('Enviar Disputa', style: TextStyle(color: Colors.white)),
          ),
        ],
      );
    },
  );
}
