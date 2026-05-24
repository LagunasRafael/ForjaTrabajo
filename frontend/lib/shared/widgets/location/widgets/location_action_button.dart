import 'package:flutter/material.dart';

class LocationActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isPrimary;
  final bool isLoading;
  final VoidCallback? onPressed;

  const LocationActionButton._({
    super.key,
    required this.icon,
    required this.label,
    required this.isPrimary,
    required this.isLoading,
    required this.onPressed,
  });

  const LocationActionButton.primary({
    Key? key,
    required IconData icon,
    required String label,
    bool isLoading = false,
    VoidCallback? onPressed,
  }) : this._(
          key: key,
          icon: icon,
          label: label,
          isPrimary: true,
          isLoading: isLoading,
          onPressed: onPressed,
        );

  const LocationActionButton.outlined({
    Key? key,
    required IconData icon,
    required String label,
    VoidCallback? onPressed,
  }) : this._(
          key: key,
          icon: icon,
          label: label,
          isPrimary: false,
          isLoading: false,
          onPressed: onPressed,
        );

  static const Color _primaryColor = Color(0xFF4F46E5);

  @override
  Widget build(BuildContext context) {
    if (isPrimary) {
      return SizedBox(
        width: double.infinity,
        height: 58,
        child: ElevatedButton.icon(
          onPressed: onPressed,
          icon: isLoading
              ? const SizedBox(
                  width: 19,
                  height: 19,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Icon(icon),
          label: Text(label),
          style: ElevatedButton.styleFrom(
            backgroundColor: _primaryColor,
            foregroundColor: Colors.white,
            elevation: 4,
            shadowColor: _primaryColor.withValues(alpha: 0.28),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 58,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: _primaryColor,
          side: const BorderSide(color: _primaryColor, width: 1.4),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}