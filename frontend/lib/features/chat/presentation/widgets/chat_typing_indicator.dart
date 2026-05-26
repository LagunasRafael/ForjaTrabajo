import 'package:flutter/material.dart';

class ChatTypingIndicator extends StatelessWidget {
  final String? otherUserName;

  const ChatTypingIndicator({super.key, this.otherUserName});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            otherUserName != null ? "$otherUserName está escribiendo" : "Escribiendo",
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontStyle: FontStyle.italic),
          ),
          const SizedBox(width: 8),
          const SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF4F46E5)),
          ),
        ],
      ),
    );
  }
}
