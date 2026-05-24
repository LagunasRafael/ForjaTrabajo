import 'package:flutter/material.dart';

class ApplyLocationButton extends StatelessWidget {
  final VoidCallback onPressed;

  const ApplyLocationButton({
    super.key,
    required this.onPressed,
  });

  static const Color _primaryColor = Color(0xFF4F46E5);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryColor,
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: _primaryColor.withValues(alpha: 0.28),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: const Text('Aplicar ubicación'),
      ),
    );
  }
}