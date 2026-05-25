import 'package:flutter/material.dart';

class WorkEvidenceHeader extends StatelessWidget {
  final bool isDark;

  const WorkEvidenceHeader({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(height: 40, color: isDark ? Colors.white10 : const Color(0xFFF3F4F6)),
        Row(
          children: [
            Icon(Icons.image_outlined, size: 18, color: isDark ? Colors.white60 : Colors.black54),
            const SizedBox(width: 8),
            Text(
              "EVIDENCIAS DEL TRABAJO",
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 13,
                letterSpacing: 1.2,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
      ],
    );
  }
}
