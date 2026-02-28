import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forja_trabajo/features/services/domain/entities/service_entity.dart';

// Importamos para poder navegar a los detalles
import 'package:forja_trabajo/features/auth/presentation/providers/auth_provider.dart';
import 'package:forja_trabajo/features/services/presentation/screens/shared/service_detail_screen.dart';

class ClientCompletedJobCard extends ConsumerWidget {
  final ServiceEntity service;

  const ClientCompletedJobCard({super.key, required this.service});

  void _goToDetails(BuildContext context, WidgetRef ref) {
    final user = ref.read(authProvider).user;
    if (user == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ServiceDetailScreen(
          service: service,
          currentUser: user,
          categoryName: "Historial",
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imageUrl = (service.imageUrls.isNotEmpty)
        ? service.imageUrls.first
        : 'https://picsum.photos/seed/${service.id}/400/200';

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200), // Borde suave como en el diseño
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _goToDetails(context, ref), // Tocar tarjeta para ver detalles
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImage(imageUrl),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTitleAndStars(),
                    const SizedBox(height: 6),
                    _buildWorkerInfo(),
                    const SizedBox(height: 12),
                    _buildDescription(),
                    const SizedBox(height: 16),
                    _buildActionButtons(context),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- 1. Imagen y Badge (COMPLETADO) ---
  Widget _buildImage(String url) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        child: Stack(
          children: [
            Image.network(url, height: 140, width: double.infinity, fit: BoxFit.cover),
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981), // Verde exacto de la imagen
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.check_circle, color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text(
                      "COMPLETADO",
                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );

  // --- 2. Título y Estrellas ---
  Widget _buildTitleAndStars() => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              service.title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Row(
            children: List.generate(
              5,
              (index) => const Icon(Icons.star, color: Color(0xFFFBBF24), size: 16), // Color amarillo/dorado
            ),
          ),
        ],
      );

  // --- 3. Info del Trabajador ---
  Widget _buildWorkerInfo() => Row(
        children: [
          const Icon(Icons.person, size: 14, color: Colors.grey),
          const SizedBox(width: 6),
          Text(
            service.authorName ?? "Trabajador asignado", // Si tienes el nombre del worker, úsalo aquí
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ],
      );

  // --- 4. Descripción breve ---
  Widget _buildDescription() => Text(
        service.summary ?? service.description,
        style: TextStyle(color: Colors.grey.shade700, fontSize: 13, height: 1.4),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      );

  // --- 5. Botones de Acción ---
  Widget _buildActionButtons(BuildContext context) => Row(
        children: [
          // Botón Principal: Pedir Factura
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Funcionalidad de factura en desarrollo..."))
                );
              },
              icon: const Icon(Icons.receipt_long, size: 18),
              label: const Text("Pedir Factura", style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB), // Azul fuerte
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Botón Secundario (Ícono Cuadrado): Calificar / Repetir
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              icon: const Icon(Icons.star_rate_rounded, color: Colors.black54),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Pantalla de calificación próximamente..."))
                );
              },
            ),
          )
        ],
      );
}