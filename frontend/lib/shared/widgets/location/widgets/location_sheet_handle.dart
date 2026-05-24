import 'package:flutter/material.dart';

class LocationSheetHandle extends StatelessWidget {
  const LocationSheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 46,
        height: 5,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}