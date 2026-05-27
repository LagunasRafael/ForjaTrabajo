import 'package:flutter/material.dart';
import 'package:forja_trabajo/features/chat/presentation/widgets/chat_action_item.dart';

class ChatInputActionMenu extends StatelessWidget {
  final bool isClient;
  final bool canSendOffer;
  final VoidCallback? onOffer;
  final VoidCallback? onGallery;
  final VoidCallback? onLocation;

  const ChatInputActionMenu({
    super.key,
    required this.isClient,
    required this.canSendOffer,
    this.onOffer,
    this.onGallery,
    this.onLocation,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Compartir",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ChatActionItem(
                  icon: Icons.photo_library,
                  color: Colors.blue,
                  label: "Galería",
                  onTap: () {
                    Navigator.pop(context);
                    onGallery?.call();
                  },
                ),
                ChatActionItem(
                  icon: Icons.location_on,
                  color: Colors.green,
                  label: "Ubicación",
                  onTap: () {
                    Navigator.pop(context);
                    onLocation?.call();
                  },
                ),
                if (isClient && canSendOffer)
                  ChatActionItem(
                    icon: Icons.local_offer,
                    color: const Color(0xFF4F46E5),
                    label: "Oferta",
                    onTap: () {
                      Navigator.pop(context);
                      onOffer?.call();
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
