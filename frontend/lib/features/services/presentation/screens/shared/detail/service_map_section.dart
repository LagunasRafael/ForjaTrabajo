import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart'; 

import 'package:forja_trabajo/features/services/presentation/widgets/client/maps/location_loading_placeholder.dart';
import 'package:forja_trabajo/features/services/presentation/widgets/client/maps/full_screen_map_viewer.dart';

class ServiceMapSection extends StatefulWidget {
  final double? latitude;
  final double? longitude;
  final String? exactAddress;
  final Color themeColor;

  const ServiceMapSection({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.exactAddress,
    required this.themeColor,
  });

  @override
  State<ServiceMapSection> createState() => _ServiceMapSectionState();
}

class _ServiceMapSectionState extends State<ServiceMapSection> {
  bool _isMapLoaded = false;

  @override
  void initState() {
    super.initState();
    // 🚀 RETRASO PREMIUM SEGURO:
    // Esperamos 600ms a que la transición de entrada de la pantalla termine suavemente.
    // Luego, mostramos el mapa con un fundido para evitar saltos gráficos bruscos de GPU.
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() => _isMapLoaded = true);
      }
    });
  }

  Future<void> _abrirGoogleMaps(BuildContext context) async {
    if (widget.latitude == null || widget.longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Este servicio no tiene ubicación GPS exacta registrada.")),
      );
      return;
    }

    final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=${widget.latitude},${widget.longitude}');
    
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
    final bool hasLocation = widget.latitude != null && widget.longitude != null;
    final String displayAddress = (widget.exactAddress != null && widget.exactAddress!.isNotEmpty) 
        ? widget.exactAddress! 
        : "Dirección no especificada";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "UBICACIÓN APROXIMADA", 
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1.2)
            ),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(Icons.location_on, size: 16, color: widget.themeColor),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      displayAddress, 
                      style: TextStyle(fontWeight: FontWeight.w800, color: widget.themeColor),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200, width: 1.5),
            ),
            child: hasLocation 
                ? AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    transitionBuilder: (Widget child, Animation<double> animation) {
                      return FadeTransition(opacity: animation, child: child);
                    },
                    child: _isMapLoaded
                        ? Stack(
                            key: const ValueKey('loaded_details_map'),
                            children: [
                              // 🗺️ El mapa real interactivo en los detalles
                              FlutterMap(
                                options: MapOptions(
                                  initialCenter: LatLng(widget.latitude!, widget.longitude!),
                                  initialZoom: 14.5,
                                  minZoom: 10,
                                  maxZoom: 18,
                                  interactionOptions: const InteractionOptions(
                                    flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
                                  ),
                                  onTap: (tapPosition, point) {
                                    FullScreenMapViewer.open(
                                      context,
                                      latitude: widget.latitude!,
                                      longitude: widget.longitude!,
                                      exactAddress: displayAddress,
                                      themeColor: widget.themeColor,
                                    );
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
                                        point: LatLng(widget.latitude!, widget.longitude!),
                                        width: 40,
                                        height: 40,
                                        child: Icon(
                                          Icons.location_on, 
                                          color: widget.themeColor, 
                                          size: 40
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              
                              // 🧭 Botón Premium Flotante para abrir en App de Mapas externa
                              Positioned(
                                bottom: 16,
                                right: 16,
                                child: Material(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  elevation: 3,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: () => _abrirGoogleMaps(context),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.directions_outlined, color: widget.themeColor, size: 18),
                                          const SizedBox(width: 4),
                                          Text(
                                            "Google Maps",
                                            style: TextStyle(
                                              color: widget.themeColor,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : const LocationLoadingPlaceholder(), // ⏳ Mismo cargador consistente que el Step 2
                  )
                : Center(
                    child: Text(
                      "Ubicación GPS no disponible", 
                      style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.bold)
                    )
                  ),
          ),
        ),
        const SizedBox(height: 24),
      ]
    );
  }
}