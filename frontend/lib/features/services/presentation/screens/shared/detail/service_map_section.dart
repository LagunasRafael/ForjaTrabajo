import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; 

class ServiceMapSection extends StatelessWidget {
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

  Future<void> _abrirGoogleMaps(BuildContext context) async {
    if (latitude == null || longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Este servicio no tiene ubicación GPS exacta registrada.")),
      );
      return;
    }

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
    final bool hasLocation = latitude != null && longitude != null;
    final String displayAddress = (exactAddress != null && exactAddress!.isNotEmpty) 
        ? exactAddress! 
        : "Dirección no especificada";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("UBICACIÓN APROXIMADA", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1.2)),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(Icons.location_on, size: 16, color: themeColor),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      displayAddress, 
                      style: TextStyle(fontWeight: FontWeight.w800, color: themeColor),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () => _abrirGoogleMaps(context),
          child: Container(
            height: 180, width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.blue[50], 
              borderRadius: BorderRadius.circular(16), 
              image: DecorationImage(
                image: const NetworkImage("https://placehold.co/600x300/e0e7ff/4f46e5?text=Toca+para+abrir+Google+Maps"), 
                fit: BoxFit.cover,
                colorFilter: hasLocation ? null : ColorFilter.mode(Colors.grey.shade300, BlendMode.saturation)
              )
            ),
            child: hasLocation 
                ? Center(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: themeColor, shape: BoxShape.circle, boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)]),
                      child: const Icon(Icons.map_rounded, color: Colors.white, size: 32),
                    ),
                  )
                : const Center(child: Text("Ubicación GPS no disponible", style: TextStyle(fontWeight: FontWeight.bold))),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          "La dirección exacta será revelada una vez aceptado el trabajo. Toca el mapa para ver la zona.",
          style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey, fontSize: 12),
        ),
      ]
    );
  }
}