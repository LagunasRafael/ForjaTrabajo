import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forja_trabajo/features/auth/presentation/providers/auth_provider.dart';
import 'package:forja_trabajo/features/services/presentation/providers/service_list_provider.dart';
import 'package:forja_trabajo/shared/widgets/location/location_radius_sheet.dart';

class LocationRadiusBar extends ConsumerWidget {
  const LocationRadiusBar({super.key});

  static const Color _primaryColor = Color(0xFF4F46E5);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(marketplaceLocationInitProvider);

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final authState = ref.watch(authProvider);
    final radiusKm = ref.watch(selectedRadiusKmProvider);
    final tempLabel = ref.watch(selectedMarketplaceLocationLabelProvider);
    final tempLat = ref.watch(selectedMarketplaceLatitudeProvider);
    final useFilter = ref.watch(useMarketplaceLocationFilterProvider);
    final user = authState.user;

    final bool hasActiveLocation;
    final String displayText;

    if (!useFilter) {
      hasActiveLocation = false;
      displayText = 'Todas las ubicaciones';
    } else {
      final effectiveLat = tempLat ?? user?.latitude;
      hasActiveLocation = effectiveLat != null;
      displayText = tempLabel ??
          user?.city ??
          (effectiveLat != null ? 'Ubicación actual' : 'Todas las ubicaciones');
    }

    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => const LocationRadiusSheet(),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF334155)
              : _primaryColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              Icons.location_on,
              size: 18,
              color: hasActiveLocation ? _primaryColor : Colors.grey,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                displayText,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white : const Color(0xFF111827),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (hasActiveLocation) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _primaryColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${radiusKm.toInt()} km',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _primaryColor,
                  ),
                ),
              ),
            ],
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, size: 18, color: Colors.grey.shade500),
          ],
        ),
      ),
    );
  }
}