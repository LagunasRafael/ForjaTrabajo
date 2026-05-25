import 'package:flutter/material.dart';

class WorkEvidenceEmptyState extends StatelessWidget {
  final bool isDark;

  const WorkEvidenceEmptyState({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.03) : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(Icons.image_outlined, size: 36, color: isDark ? Colors.white24 : Colors.black26),
          const SizedBox(height: 8),
          Text(
            "Aún no se han subido evidencias del trabajo.",
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white38 : Colors.black45,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
