import 'package:flutter/material.dart';

class RadiusSliderSection extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;

  const RadiusSliderSection({
    super.key,
    required this.value,
    required this.onChanged,
  });

  static const Color _primaryColor = Color(0xFF4F46E5);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Radio de búsqueda',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            Text(
              '${value.toInt()} km',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                color: _primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: _primaryColor,
            inactiveTrackColor:
                isDark ? Colors.grey.shade700 : Colors.grey.shade300,
            thumbColor: theme.colorScheme.surface,
            overlayColor: _primaryColor.withValues(alpha: 0.16),
            thumbShape: const RoundSliderThumbShape(
              enabledThumbRadius: 12,
              elevation: 3,
            ),
            trackHeight: 5,
          ),
          child: Slider(
            value: value,
            min: 5,
            max: 50,
            divisions: 9,
            label: '${value.toInt()} km',
            onChanged: onChanged,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            _SliderLimitLabel(text: '5 km'),
            _SliderLimitLabel(text: '50 km'),
          ],
        ),
      ],
    );
  }
}

class _SliderLimitLabel extends StatelessWidget {
  final String text;

  const _SliderLimitLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
    );
  }
}