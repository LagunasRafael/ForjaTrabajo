import 'package:flutter/material.dart';

class ChatNegotiationBanner extends StatelessWidget {
  final String amount;
  final VoidCallback onModify;

  const ChatNegotiationBanner({
    super.key,
    required this.amount,
    required this.onModify,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F3FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFC4B5FD)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "ESTADO DE NEGOCIACIÓN",
                style: TextStyle(
                  color: Color(0xFF4F46E5),
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                "Oferta actual: \$$amount MXN",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          ElevatedButton.icon(
            onPressed: onModify,
            icon: const Icon(Icons.edit, size: 14, color: Colors.white),
            label: const Text("Modificar", style: TextStyle(fontSize: 12, color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          )
        ],
      ),
    );
  }
}
