import 'package:flutter/material.dart';

class LocationResetActions extends StatelessWidget {
  final bool isDisabled;
  final VoidCallback onReset;
  final VoidCallback onViewAll;

  const LocationResetActions({
    super.key,
    required this.isDisabled,
    required this.onReset,
    required this.onViewAll,
  });

  static const Color _primaryColor = Color(0xFF4F46E5);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 54,
          child: OutlinedButton.icon(
            onPressed: isDisabled ? null : onReset,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Restablecer a mi ubicación'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
              side: BorderSide(
                color: Theme.of(context).colorScheme.outline,
                width: 1.2,
              ),
              textStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        TextButton.icon(
          onPressed: isDisabled ? null : onViewAll,
          icon: const Icon(Icons.public_rounded, size: 20),
          label: const Text('Ver todas las ubicaciones'),
          style: TextButton.styleFrom(
            foregroundColor: _primaryColor,
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}