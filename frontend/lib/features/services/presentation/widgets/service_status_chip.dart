
import 'package:flutter/material.dart';
import 'package:forja_trabajo/features/services/domain/entities/service_entity.dart';

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

  String _translateStatus(dynamic status) {
    // 1. Lo convertimos a texto a la fuerza cortando el "JobStatus."
    final statusString = status.toString().split('.').last.toLowerCase();

    // 2. Lo traducimos a un español presentable
    switch (statusString) {
      case 'open':
        return 'Disponible';
      case 'inprogress':
      case 'in_progress':
        return 'En Progreso';
      case 'completed':
        return 'Completado';
      case 'cancelled':
        return 'Cancelado';
      default:
        return 'Pendiente';
    }
  }
  
}