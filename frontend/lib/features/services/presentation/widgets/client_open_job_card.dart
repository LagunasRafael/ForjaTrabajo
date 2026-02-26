import 'package:flutter/material.dart';
import 'package:forja_trabajo/features/services/domain/entities/service_entity.dart';
import '../screens/client/offers_received_screen.dart'; // Para navegar al ver postulados

class ClientOpenJobCard extends StatelessWidget {
  final ServiceEntity service;

  const ClientOpenJobCard({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    // Si no hay imagen, usamos una por defecto
    final imageUrl = (service.imageUrls.isNotEmpty)
        ? service.imageUrls.first
        : 'https://picsum.photos/seed/${service.id}/800/400';

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. IMAGEN DE CABECERA
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Image.network(
              imageUrl,
              height: 160,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 160,
                color: Colors.grey[200],
                child: const Icon(Icons.image, color: Colors.grey),
              ),
            ),
          ),

          // 2. CONTENIDO
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Título y Precio
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        service.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          color: Color(0xFF111827),
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "\$${service.basePrice.toStringAsFixed(0)}",
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        color: Color(0xFF10B981), // Verde
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 6),
                
                // Ubicación y Fecha (Metadata)
                Text(
                  "Publicado el ${_formatDate(service.createdAt)} • ${service.exactAddress ?? 'Ubicación remota'}",
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 20),

                // 3. BOTONES DE ACCIÓN (Tal cual la imagen)
                Row(
                  children: [
                    // Botón Principal: Ver Postulados
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // Navegamos a la pantalla de ofertas
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => OffersReceivedScreen(service: service)),
                          );
                        },
                        icon: const Icon(Icons.people_alt_rounded, size: 20),
                        label: const Text("Ver Postulados"), 
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4F46E5), // Azul/Indigo
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 12),
                    
                    // Botón Secundario: Cancelar (La X roja)
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2), // Fondo rojo muy suave
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFEE2E2)),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Color(0xFFEF4444)),
                        onPressed: () {
                          // Aquí implementaremos la lógica de borrar después
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Opción de eliminar pendiente"))
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}";
  }
}