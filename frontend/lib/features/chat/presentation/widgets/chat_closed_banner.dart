import 'package:flutter/material.dart';

class ChatClosedBanner extends StatelessWidget {
  final String? closedReason;

  const ChatClosedBanner({super.key, this.closedReason});

  String _translateClosedReason(String? reason) {
    switch (reason) {
      case 'WORKER_NOT_SELECTED': return 'Se seleccionó otro trabajador';
      case 'CLIENT_PAYMENT_TIMEOUT': return 'El pago no se realizó a tiempo';
      case 'APPLICATION_WITHDRAWN': return 'El trabajador retiró su postulación';
      case 'SERVICE_CANCELLED': return 'El servicio fue cancelado';
      case 'SERVICE_COMPLETED': return 'Servicio completado';
      case 'SERVICE_COMPLETED_AUTO': return 'Servicio completado automáticamente';
      case 'DISPUTE_RESOLVED': return 'Disputa resuelta';
      default: return 'Chat finalizado';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.grey.shade100,
      child: Row(
        children: [
          const Icon(Icons.lock_outline, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _translateClosedReason(closedReason),
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
