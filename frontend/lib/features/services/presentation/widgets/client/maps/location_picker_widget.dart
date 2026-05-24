import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:forja_trabajo/features/services/domain/usecases/location/get_device_location_usecase.dart';
import 'package:forja_trabajo/features/services/presentation/widgets/client/create_service_widgets.dart';
import 'package:forja_trabajo/shared/widgets/maps/nominatim_service.dart';
import 'package:forja_trabajo/shared/widgets/maps/address_suggestions_card.dart';
import 'package:forja_trabajo/shared/widgets/maps/interactive_location_map.dart';
import 'package:forja_trabajo/shared/widgets/maps/location_loading_placeholder.dart';
import 'package:forja_trabajo/shared/widgets/maps/address_search_input.dart';

class LocationPickerWidget extends ConsumerStatefulWidget {
  final TextEditingController addressCtrl;
  final double? lat;
  final double? lng;
  final Function(double lat, double lng) onLocationCaptured;

  const LocationPickerWidget({
    super.key,
    required this.addressCtrl,
    required this.onLocationCaptured,
    this.lat,
    this.lng,
  });

  @override
  ConsumerState<LocationPickerWidget> createState() => _LocationPickerWidgetState();
}

class _LocationPickerWidgetState extends ConsumerState<LocationPickerWidget> {
  final MapController _mapController = MapController();
  final FocusNode _addressFocusNode = FocusNode();
  
  bool _isLocating = false;
  bool _isSearchingSuggestions = false;
  bool _isInitialLocationLoaded = false;
  List<Map<String, dynamic>> _suggestions = [];
  Timer? _debounce;
  
  LatLng _currentCenter = const LatLng(20.659698, -103.349609);

  @override
  void initState() {
    super.initState();
    if (widget.lat != null && widget.lng != null) {
      _currentCenter = LatLng(widget.lat!, widget.lng!);
      _isInitialLocationLoaded = true;
      
      if (widget.addressCtrl.text.isEmpty) {
        Future.microtask(() async {
          final address = await NominatimService.reverseGeocode(widget.lat!, widget.lng!);
          if (address.isNotEmpty && mounted) {
            widget.addressCtrl.text = address;
          }
        });
      }
    } else {
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          _handleGetLocation(silent: true);
        }
      });
    }
    _addressFocusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _addressFocusNode.removeListener(_onFocusChange);
    _addressFocusNode.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_addressFocusNode.hasFocus) {
      setState(() => _suggestions = []);
    }
  }

  void _onAddressChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    
    _debounce = Timer(const Duration(milliseconds: 600), () async {
      if (query.trim().length < 3) {
        setState(() => _suggestions = []);
        return;
      }
      
      if (_addressFocusNode.hasFocus) {
        setState(() => _isSearchingSuggestions = true);
        final results = await NominatimService.searchAddresses(query);
        setState(() {
          _suggestions = results;
          _isSearchingSuggestions = false;
        });
      }
    });
  }

  Future<void> _updateLocationFromCoordinates(double lat, double lng) async {
    setState(() {
      _currentCenter = LatLng(lat, lng);
      _isLocating = true;
    });
    
    widget.onLocationCaptured(lat, lng);
    _mapController.move(_currentCenter, 15.5);

    final address = await NominatimService.reverseGeocode(lat, lng);
    
    setState(() => _isLocating = false);
    if (address.isNotEmpty) {
      widget.addressCtrl.text = address;
    }
  }

  Future<void> _handleGetLocation({bool silent = false}) async {
    if (silent && (widget.lat != null || widget.lng != null)) return;

    if (!silent) {
      FocusScope.of(context).unfocus();
      setState(() => _isLocating = true);
    }

    try {
      final locationUseCase = ref.read(getDeviceLocationUseCaseProvider);
      final (latitude, longitude, address) = await locationUseCase.execute().timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception("Timeout al obtener ubicación."),
      );

      if (silent && (widget.lat != null || widget.lng != null)) return;

      widget.onLocationCaptured(latitude, longitude);
      setState(() => _currentCenter = LatLng(latitude, longitude));
      _mapController.move(_currentCenter, 15.5);
      
      if (address.isNotEmpty && address != "Dirección no encontrada automáticamente") {
        widget.addressCtrl.text = address;
      }
    } catch (e) {
      if (mounted && !silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al buscar ubicación: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          if (!silent) _isLocating = false;
          _isInitialLocationLoaded = true; 
        });
      }
    }
  }

  void _selectSuggestion(Map<String, dynamic> suggestion) {
    final lat = suggestion['lat'];
    final lon = suggestion['lon'];
    final formattedAddress = NominatimService.formatAddress(suggestion);

    setState(() {
      _currentCenter = LatLng(lat, lon);
      _suggestions = [];
    });

    widget.addressCtrl.text = formattedAddress;
    widget.onLocationCaptured(lat, lon);
    _mapController.move(_currentCenter, 15.5);
    _addressFocusNode.unfocus();
  }

  void _updateLocationAndAddress(double lat, double lng, String address) {
    setState(() {
      _currentCenter = LatLng(lat, lng);
    });
    widget.onLocationCaptured(lat, lng);
    _mapController.move(_currentCenter, 15.5);
    if (address.isNotEmpty) {
      widget.addressCtrl.text = address;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AbsorbPointer(
      absorbing: _isLocating,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(opacity: animation, child: child);
            },
            child: _isInitialLocationLoaded
                ? InteractiveLocationMap(
                    key: const ValueKey('location_picker_map'),
                    mapController: _mapController,
                    currentCenter: _currentCenter,
                    lat: widget.lat,
                    lng: widget.lng,
                    isLocating: _isLocating,
                    currentAddress: widget.addressCtrl.text,
                    onTapMap: _updateLocationFromCoordinates,
                    onTapGPS: () => _handleGetLocation(),
                    onLocationConfirmed: _updateLocationAndAddress,
                  )
                : const LocationLoadingPlaceholder(),
          ),
          
          const SizedBox(height: 32),
          const ServiceSectionLabel("Dirección detallada"),
          
          AddressSearchInput(
            controller: widget.addressCtrl,
            focusNode: _addressFocusNode,
            onChanged: _onAddressChanged,
            onClear: () {
              widget.addressCtrl.clear();
              setState(() => _suggestions = []);
            },
          ),
          
          if (_isSearchingSuggestions)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF4F46E5)))),
            ),
            
          AddressSuggestionsCard(
            suggestions: _suggestions,
            onSuggestionSelected: _selectSuggestion,
          ),
        ],
      ),
    );
  }
}
