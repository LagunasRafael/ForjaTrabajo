import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart';

import 'package:forja_trabajo/features/auth/presentation/providers/auth_provider.dart';
import 'package:forja_trabajo/features/services/presentation/providers/service_list_provider.dart';
import 'package:forja_trabajo/shared/widgets/location/marketplace_location_storage.dart';
import 'package:forja_trabajo/shared/widgets/maps/full_screen_location_picker.dart';

import 'package:forja_trabajo/shared/widgets/location/widgets/apply_location_button.dart';
import 'package:forja_trabajo/shared/widgets/location/widgets/location_action_button.dart';
import 'package:forja_trabajo/shared/widgets/location/widgets/location_reset_actions.dart';
import 'package:forja_trabajo/shared/widgets/location/widgets/location_sheet_handle.dart';
import 'package:forja_trabajo/shared/widgets/location/widgets/location_sheet_header.dart';
import 'package:forja_trabajo/shared/widgets/location/widgets/location_summary_card.dart';
import 'package:forja_trabajo/shared/widgets/location/widgets/radius_slider_section.dart';

class LocationRadiusSheet extends ConsumerStatefulWidget {
  const LocationRadiusSheet({super.key});

  @override
  ConsumerState<LocationRadiusSheet> createState() =>
      _LocationRadiusSheetState();
}

class _LocationRadiusSheetState extends ConsumerState<LocationRadiusSheet> {
  late double _sliderValue;
  bool _isLocating = false;

  @override
  void initState() {
    super.initState();
    _sliderValue = ref.read(selectedRadiusKmProvider);
  }

  Future<void> _handleGetLocation() async {
    setState(() => _isLocating = true);

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        _showSnackBar('Activa el GPS para usar tu ubicación.');
        return;
      }

      var permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();

        if (permission == LocationPermission.denied) {
          _showSnackBar('Permiso de ubicación denegado.');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showSnackBar('Activa el permiso de ubicación desde ajustes.');
        return;
      }

      final position = await _getCurrentOrLastKnownPosition();

      if (position == null) {
        _showSnackBar('No se pudo obtener tu ubicación.');
        return;
      }

      final label = await _resolveLocationLabel(position);

      await _saveMarketplaceLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        label: label,
      );

      _showSnackBar(
        'Ubicación: $label',
        backgroundColor: const Color(0xFF4F46E5),
      );
    } catch (_) {
      _showSnackBar('No se pudo obtener tu ubicación.');
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  Future<Position?> _getCurrentOrLastKnownPosition() async {
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        forceAndroidLocationManager: true,
        timeLimit: const Duration(seconds: 12),
      );
    } catch (_) {
      return Geolocator.getLastKnownPosition();
    }
  }

  Future<String> _resolveLocationLabel(Position position) async {
    var label = 'Ubicación actual';

    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      ).timeout(const Duration(seconds: 5));

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        label = place.locality ?? place.subAdministrativeArea ?? label;
      }
    } catch (_) {}

    return label;
  }

  Future<void> _handleOpenMapPicker() async {
    final currentLat = ref.read(selectedMarketplaceLatitudeProvider);
    final currentLng = ref.read(selectedMarketplaceLongitudeProvider);
    final currentLabel = ref.read(selectedMarketplaceLocationLabelProvider);
    final user = ref.read(authProvider).user;

    final initialCenter = LatLng(
      currentLat ?? user?.latitude ?? 20.659698,
      currentLng ?? user?.longitude ?? -103.349609,
    );

    final result = await FullScreenLocationPicker.open(
      context,
      initialCenter: initialCenter,
      initialAddress: currentLabel ?? user?.city ?? '',
    );

    if (result == null) return;

    final label = result.address.isNotEmpty
        ? result.address
        : 'Ubicación seleccionada';

    await _saveMarketplaceLocation(
      latitude: result.latitude,
      longitude: result.longitude,
      label: label,
    );
  }

  Future<void> _saveMarketplaceLocation({
    required double latitude,
    required double longitude,
    required String label,
  }) async {
    ref.read(selectedMarketplaceLatitudeProvider.notifier).state = latitude;
    ref.read(selectedMarketplaceLongitudeProvider.notifier).state = longitude;
    ref.read(selectedMarketplaceLocationLabelProvider.notifier).state = label;
    ref.read(useMarketplaceLocationFilterProvider.notifier).state = true;

    await MarketplaceLocationStorage.saveLocation(
      latitude: latitude,
      longitude: longitude,
      label: label,
    );

    await MarketplaceLocationStorage.saveFilterEnabled(true);
  }

  Future<void> _handleResetToSaved() async {
    ref.read(selectedMarketplaceLatitudeProvider.notifier).state = null;
    ref.read(selectedMarketplaceLongitudeProvider.notifier).state = null;
    ref.read(selectedMarketplaceLocationLabelProvider.notifier).state = null;
    ref.read(useMarketplaceLocationFilterProvider.notifier).state = true;

    await MarketplaceLocationStorage.clearLocation();
    await MarketplaceLocationStorage.saveFilterEnabled(true);

    if (mounted) Navigator.pop(context);
  }

  Future<void> _handleViewAll() async {
    ref.read(selectedMarketplaceLatitudeProvider.notifier).state = null;
    ref.read(selectedMarketplaceLongitudeProvider.notifier).state = null;
    ref.read(selectedMarketplaceLocationLabelProvider.notifier).state = null;
    ref.read(useMarketplaceLocationFilterProvider.notifier).state = false;

    await MarketplaceLocationStorage.clearLocation();
    await MarketplaceLocationStorage.saveFilterEnabled(false);

    if (mounted) Navigator.pop(context);
  }

  Future<void> _handleApply() async {
    ref.read(selectedRadiusKmProvider.notifier).state = _sliderValue;
    await MarketplaceLocationStorage.saveRadius(_sliderValue);

    if (mounted) Navigator.pop(context);
  }

  String _getCurrentLocationLabel() {
    final useFilter = ref.watch(useMarketplaceLocationFilterProvider);
    final tempLabel = ref.watch(selectedMarketplaceLocationLabelProvider);
    final tempLat = ref.watch(selectedMarketplaceLatitudeProvider);
    final user = ref.watch(authProvider).user;

    if (!useFilter) return 'Todas las ubicaciones';

    final effectiveLat = tempLat ?? user?.latitude;

    return tempLabel ??
        user?.city ??
        (effectiveLat != null ? 'Ubicación actual' : 'Sin ubicación');
  }

  void _showSnackBar(String message, {Color? backgroundColor}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(isLocatingMarketplaceProvider) || _isLocating;
    final theme = Theme.of(context);
    final locationLabel = _getCurrentLocationLabel();

    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 12,
          bottom: 24 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const LocationSheetHandle(),
              const SizedBox(height: 26),
              const LocationSheetHeader(),
              const SizedBox(height: 22),

              LocationSummaryCard(
                label: locationLabel,
                onTap: isLoading ? null : _handleOpenMapPicker,
              ),

              const SizedBox(height: 20),

              LocationActionButton.primary(
                icon: Icons.my_location_rounded,
                label: isLoading ? 'Localizando...' : 'Usar mi ubicación actual',
                isLoading: isLoading,
                onPressed: isLoading ? null : _handleGetLocation,
              ),

              const SizedBox(height: 12),

              LocationActionButton.outlined(
                icon: Icons.map_outlined,
                label: 'Elegir en mapa',
                onPressed: isLoading ? null : _handleOpenMapPicker,
              ),

              const SizedBox(height: 22),

              RadiusSliderSection(
                value: _sliderValue,
                onChanged: (value) => setState(() => _sliderValue = value),
              ),

              const SizedBox(height: 24),

              LocationResetActions(
                isDisabled: isLoading,
                onReset: _handleResetToSaved,
                onViewAll: _handleViewAll,
              ),

              const SizedBox(height: 24),

              ApplyLocationButton(
                onPressed: _handleApply,
              ),
            ],
          ),
        ),
      ),
    );
  }
}