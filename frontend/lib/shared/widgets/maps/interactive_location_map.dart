import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'full_screen_location_picker.dart';

class InteractiveLocationMap extends StatelessWidget {
  final MapController mapController;
  final LatLng currentCenter;
  final double? lat;
  final double? lng;
  final bool isLocating;
  final String currentAddress;
  final Function(double lat, double lng) onTapMap;
  final VoidCallback onTapGPS;
  final Function(double lat, double lng, String address) onLocationConfirmed;

  const InteractiveLocationMap({
    super.key,
    required this.mapController,
    required this.currentCenter,
    required this.isLocating,
    required this.currentAddress,
    required this.onTapMap,
    required this.onTapGPS,
    required this.onLocationConfirmed,
    this.lat,
    this.lng,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasLocation = lat != null && lng != null;

    return Container(
      height: 250,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFE5E7EB),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: hasLocation ? const Color(0xFF10B981) : Colors.grey.shade300,
          width: hasLocation ? 2 : 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: [
            FlutterMap(
              mapController: mapController,
              options: MapOptions(
                initialCenter: currentCenter,
                initialZoom: 15.0,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                ),
                onTap: (tapPosition, point) {
                  onTapMap(point.latitude, point.longitude);
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.forjatrabajo.app',
                ),
                if (hasLocation)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(lat!, lng!),
                        width: 45,
                        height: 45,
                        child: const Icon(
                          Icons.location_on,
                          size: 40,
                          color: Color(0xFFEF4444),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            
            // 🧭 Botón GPS Locator Flotante (Esquina Inferior Derecha)
            Positioned(
              bottom: 16,
              right: 16,
              child: FloatingActionButton.small(
                heroTag: 'gps_map_fab',
                onPressed: onTapGPS,
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF4F46E5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: isLocating 
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5, 
                        color: Color(0xFF4F46E5)
                      ),
                    )
                  : const Icon(Icons.my_location),
              ),
            ),

            // 🔍 Botón Expandir a Pantalla Completa (Esquina Superior Derecha)
            Positioned(
              top: 12,
              right: 12,
              child: Material(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(12),
                elevation: 3,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () async {
                    final result = await FullScreenLocationPicker.open(
                      context,
                      initialCenter: currentCenter,
                      initialAddress: currentAddress,
                      themeColor: const Color(0xFF4F46E5),
                    );
                    if (result != null) {
                      onLocationConfirmed(result.latitude, result.longitude, result.address);
                    }
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(10.0),
                    child: Icon(
                      Icons.open_in_full_rounded,
                      color: Color(0xFF4F46E5),
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
            
            // ℹ️ Etiqueta de Estado de Ubicación (Esquina Superior Izquierda)
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                    )
                  ]
                ),
                child: Row(
                  children: [
                    Icon(
                      hasLocation ? Icons.check_circle : Icons.info, 
                      size: 14, 
                      color: hasLocation ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      hasLocation ? "Ubicación fijada" : "Toca el mapa o usa el GPS",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: hasLocation ? const Color(0xFF065F46) : const Color(0xFF991B1B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
