import 'package:flutter/material.dart';

class ChatDayDivider extends StatelessWidget {
  final String label;

  const ChatDayDivider({super.key, required this.label});

  factory ChatDayDivider.fromDateTime(DateTime date) {
    final now = DateTime.now();
    final local = date.toLocal();
    final today = DateTime(now.year, now.month, now.day);
    final msgDate = DateTime(local.year, local.month, local.day);

    final diff = today.difference(msgDate).inDays;
    String label;
    if (diff == 0) {
      label = "Hoy";
    } else if (diff == 1) {
      label = "Ayer";
    } else {
      const months = [
        'ene', 'feb', 'mar', 'abr', 'may', 'jun',
        'jul', 'ago', 'sep', 'oct', 'nov', 'dic'
      ];
      label = "${local.day} ${months[local.month - 1]}";
      if (local.year != now.year) {
        label += " ${local.year}";
      }
    }

    return ChatDayDivider(label: label);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 1,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 1,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
    );
  }
}
