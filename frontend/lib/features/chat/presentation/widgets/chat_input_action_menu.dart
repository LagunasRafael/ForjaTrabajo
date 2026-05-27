import 'package:flutter/material.dart';

class ChatInputActionMenu extends StatelessWidget {
  final bool isClient;
  final bool canSendOffer;
  final VoidCallback? onOffer;
  final VoidCallback? onGallery;
  final VoidCallback? onLocation;
  final VoidCallback? onAudio;

  const ChatInputActionMenu({
    super.key,
    required this.isClient,
    required this.canSendOffer,
    this.onOffer,
    this.onGallery,
    this.onLocation,
    this.onAudio,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isClient && canSendOffer)
              ListTile(
                leading: const Icon(Icons.local_offer, color: Color(0xFF4F46E5)),
                title: const Text("Generar Oferta", style: TextStyle(fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pop(context);
                  onOffer?.call();
                },
              ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.blue),
              title: const Text("Galería"),
              onTap: () {
                Navigator.pop(context);
                onGallery?.call();
              },
            ),
            ListTile(
              leading: const Icon(Icons.location_on, color: Colors.green),
              title: const Text("Compartir Ubicación"),
              onTap: () {
                Navigator.pop(context);
                onLocation?.call();
              },
            ),
            ListTile(
              leading: const Icon(Icons.audiotrack, color: Colors.orange),
              title: const Text("Enviar Audio"),
              onTap: () {
                Navigator.pop(context);
                onAudio?.call();
              },
            ),
          ],
        ),
      ),
    );
  }
}
