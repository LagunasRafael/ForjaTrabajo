import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'nominatim_service.dart';
import 'location_confirmation_card.dart';

class FullScreenLocationResult {
  final double latitude;
  final double longitude;
  final String address;

  FullScreenLocationResult({
    required this.latitude,
    required this.longitude,
    required this.address,
  });
}

class FullScreenLocationPicker extends StatefulWidget {
  final LatLng initialCenter;
  final String initialAddress;
  final Color themeColor;

  const FullScreenLocationPicker({
    super.key,
    required this.initialCenter,
    required this.initialAddress,
    this.themeColor = const Color(0xFF4F46E5),
  });

  static Future<FullScreenLocationResult?> open(
    BuildContext context, {
    required LatLng initialCenter,
    required String initialAddress,
    Color themeColor = const Color(0xFF4F46E5),
  }) {
    return Navigator.push<FullScreenLocationResult>(
      context,
      MaterialPageRoute(
        builder: (_) => FullScreenLocationPicker(
          initialCenter: initialCenter,
          initialAddress: initialAddress,
          themeColor: themeColor,
        ),
      ),
    );
  }

  @override
  State<FullScreenLocationPicker> createState() => _FullScreenLocationPickerState();
}

class _FullScreenLocationPickerState extends State<FullScreenLocationPicker> {
  final MapController _mapController = MapController();
  late LatLng _selectedCenter;
  late String _currentAddress;
  bool _isLocating = false;

  @override
  void initState() {
    super.initState();
    _selectedCenter = widget.initialCenter;
    _currentAddress = widget.initialAddress.isEmpty ? "Dirección no seleccionada" : widget.initialAddress;
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _updateLocation(double lat, double lng) async {
    setState(() {
      _selectedCenter = LatLng(lat, lng);
      _isLocating = true;
    });

    _mapController.move(_selectedCenter, 16.0);

    final address = await NominatimService.reverseGeocode(lat, lng);

    if (mounted) {
      setState(() {
        _isLocating = false;
        if (address.isNotEmpty) {
          _currentAddress = address;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 🗺️ Mapa Gigante Interactivo a Pantalla Completa
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _selectedCenter,
              initialZoom: 15.5,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
              onTap: (tapPosition, point) {
                _updateLocation(point.latitude, point.longitude);
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.forja_trabajo',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _selectedCenter,
                    width: 50,
                    height: 50,
                    child: Icon(
                      Icons.location_on,
                      color: widget.themeColor,
                      size: 48,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // 🔙 Botón flotante para regresar (Esquina Superior Izquierda)
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            child: Material(
              color: Colors.white,
              elevation: 4,
              shape: const CircleBorder(),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),

          // ℹ️ Cabecera flotante informativa
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 80,
            right: 80,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.75),
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Center(
                child: Text(
                  "Toca el mapa para fijar pin",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),

          // 💳 Card de Confirmación Inferior Modular
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: LocationConfirmationCard(
              address: _currentAddress,
              isLocating: _isLocating,
              themeColor: widget.themeColor,
              onConfirm: () {
                Navigator.pop(
                  context,
                  FullScreenLocationResult(
                    latitude: _selectedCenter.latitude,
                    longitude: _selectedCenter.longitude,
                    address: _currentAddress == "Dirección no seleccionada" ? "" : _currentAddress,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
