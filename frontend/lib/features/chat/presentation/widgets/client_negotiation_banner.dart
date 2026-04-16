import 'package:flutter/material.dart';

class ClientNegotiationBanner extends StatelessWidget {
  final String lastOfferAmount;
  final VoidCallback onModifyPressed;

  const ClientNegotiationBanner({
    super.key, 
    required this.lastOfferAmount, 
    required this.onModifyPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F3FF), // Morado muy clarito
        border: Border.all(color: const Color(0xFFC4B5FD)), // Borde morado
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // TEXTOS DE LA IZQUIERDA
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "ESTADO DE NEGOCIACIÓN",
                  style: TextStyle(
                    color: Color(0xFF4F46E5), // Morado fuerte
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Tu oferta: \$$lastOfferAmount",
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          
          // BOTÓN VERDE DE LA DERECHA
          ElevatedButton.icon(
            onPressed: onModifyPressed,
            icon: const Icon(Icons.edit, size: 16),
            label: const Text("Modificar\nContraoferta", textAlign: TextAlign.center, style: TextStyle(fontSize: 12, height: 1.1)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981), // Verde esmeralda
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }
}