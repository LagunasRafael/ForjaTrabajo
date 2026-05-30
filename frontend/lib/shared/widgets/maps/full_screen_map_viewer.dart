import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:ui';

class FullScreenMapViewer extends StatelessWidget {
  final double latitude;
  final double longitude;
  final String exactAddress;
  final Color themeColor;

  const FullScreenMapViewer({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.exactAddress,
    required this.themeColor,
  });

  static void open(
    BuildContext context, {
    required double latitude,
    required double longitude,
    required String exactAddress,
    required Color themeColor,
  }) {
    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black.withOpacity(0.5),
        pageBuilder: (context, _, __) => FullScreenMapViewer(
          latitude: latitude,
          longitude: longitude,
          exactAddress: exactAddress,
          themeColor: themeColor,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    );
  }

  Future<void> _abrirGoogleMaps(BuildContext context) async {
    final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$latitude,$longitude');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No se pudo abrir la aplicación de mapas.")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.3),
      body: Stack(
        children: [
          // 🗺️ Mapa a Pantalla Completa
          FlutterMap(
            options: MapOptions(
              initialCenter: LatLng(latitude, longitude),
              initialZoom: 16.0,
              minZoom: 10,
              maxZoom: 18,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.ForjaTrabajo.app',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: LatLng(latitude, longitude),
                    width: 50,
                    height: 50,
                    child: Icon(
                      Icons.location_on,
                      color: themeColor,
                      size: 48,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // 🔙 Botón de Atrás y Badge Superior
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Material(
                  color: Colors.white.withOpacity(0.9),
                  elevation: 4,
                  shape: const CircleBorder(),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Text(
                        "Ubicación de Trabajo",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 48), // Espaciador para centrar
              ],
            ),
          ),

          // 🧭 Botón Flotante de Google Maps (Esquina Inferior Derecha)
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 24,
            right: 16,
            child: FloatingActionButton.extended(
              heroTag: 'fullscreen_maps_route_fab',
              onPressed: () => _abrirGoogleMaps(context),
              backgroundColor: Colors.white,
              foregroundColor: themeColor,
              elevation: 4,
              icon: const Icon(Icons.directions_outlined),
              label: const Text(
                "Cómo llegar",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
