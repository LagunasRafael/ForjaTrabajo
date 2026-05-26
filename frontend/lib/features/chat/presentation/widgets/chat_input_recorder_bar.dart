import 'package:flutter/material.dart';

class ChatInputRecorderBar extends StatelessWidget {
  final bool isLocked;
  final VoidCallback? onCancel;
  final String? otherUserName;

  const ChatInputRecorderBar({
    super.key,
    required this.isLocked,
    this.onCancel,
    this.otherUserName,
  });

  @override
  Widget build(BuildContext context) {
    if (isLocked) {
      return Row(
        children: [
          TextButton.icon(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            label: const Text("Cancelar", style: TextStyle(color: Colors.red)),
            onPressed: onCancel,
          ),
          Expanded(
            child: Center(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 1.0, end: 0.0),
                duration: const Duration(milliseconds: 800),
                builder: (context, value, child) => Opacity(
                  opacity: value,
                  child: const Text(
                    "Grabando (Manos Libres)",
                    style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const Icon(Icons.mic, color: Colors.red),
          const SizedBox(width: 8),
          const Icon(Icons.lock_outline, size: 16, color: Colors.grey),
          const SizedBox(width: 4),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 1.0, end: 0.0),
            duration: const Duration(milliseconds: 800),
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: const Text("Desliza ⬆ para bloquear", style: TextStyle(color: Colors.red, fontSize: 13)),
              );
            },
            onEnd: () {},
          ),
        ],
      ),
    );
  }
}
