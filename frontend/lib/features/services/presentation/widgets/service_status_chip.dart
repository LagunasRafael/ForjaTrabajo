
import 'package:flutter/material.dart';

class ServiceStatusChip extends StatelessWidget {
  final String status;

  const ServiceStatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String text;

    // Lógica de colores según el estado que venga de FastAPI
    switch (status.toLowerCase()) {
      case 'open':
      case 'abierto':
        color = Colors.blue;
        text = 'Abierto';
        break;
      case 'in_progress':
      case 'en proceso':
        color = Colors.orange;
        text = 'En Proceso';
        break;
      case 'completed':
      case 'finalizado':
        color = Colors.green;
        text = 'Finalizado';
        break;
      case 'cancelled':
      case 'cancelado':
        color = Colors.red;
        text = 'Cancelado';
        break;
      default:
        color = Colors.grey;
        text = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1), // Fondo clarito
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)), // Borde sutil
      ),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}