import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:forja_trabajo/features/services/domain/entities/service_entity.dart';
import 'package:forja_trabajo/features/services/presentation/screens/shared/utils/category_icon_helper.dart';
import 'package:forja_trabajo/features/services/presentation/screens/shared/detail/service_image_carousel.dart';
import 'package:forja_trabajo/features/services/presentation/screens/shared/detail/service_map_section.dart';
import 'package:forja_trabajo/features/services/presentation/screens/shared/detail/widgets/service_profile_tiles.dart';
import 'package:forja_trabajo/features/services/presentation/screens/shared/detail/work_evidence/work_evidence_section.dart';

class ServiceDetailBody extends StatelessWidget {
  final ServiceEntity service;
  final String categoryName;
  final String authorName;
  final bool isOwner;
  final String? authorImageUrl;
  final String? authorId;

  const ServiceDetailBody({
    super.key,
    required this.service,
    required this.categoryName,
    required this.authorName,
    required this.isOwner,
    this.authorImageUrl,
    this.authorId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final mainColor = categoryName.toCategoryColor;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. EL CARRUSEL DE IMÁGENES
          ServiceImageCarousel(imageUrls: service.imageUrls),
          
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, 
              children: [
                _buildCategoryHeader(mainColor),
                const SizedBox(height: 12),
                
                // 🎨 Título adaptable
                Text(
                  service.title, 
                  style: TextStyle(
                    fontSize: 24, 
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87
                  )
                ),
                
                const SizedBox(height: 8),
                
                // 💰 El precio
                Text(
                  "\$${service.basePrice.toStringAsFixed(0)} MXN", 
                  style: TextStyle(
                    fontSize: 22, 
                    fontWeight: FontWeight.w900, 
                    color: isDark ? const Color(0xFF34D399) : const Color(0xFF10B981)
                  )
                ),
                const SizedBox(height: 8),

                // 📅 Fecha de publicación
                Row(
                  children: [
                    Icon(Icons.calendar_today_outlined, size: 14, color: isDark ? Colors.white60 : Colors.black54),
                    const SizedBox(width: 6),
                    Text(
                      "Publicado el ${DateFormat('dd MMM yyyy, hh:mm a').format(service.createdAt.toLocal())}",
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white60 : Colors.black54,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),

                // 🎨 Divisores y perfiles
                Divider(height: 40, color: isDark ? Colors.white10 : const Color(0xFFF3F4F6)),
                
                // Perfil del publicador
                ServiceAuthorTile(
                  authorName: authorName,
                  authorImageUrl: authorImageUrl,
                  authorId: authorId,
                  isOwner: isOwner,
                  themeColor: mainColor,
                  isDark: isDark,
                ),

                // Perfil del trabajador (si está asignado)
                if (service.workerName != null && service.workerName!.isNotEmpty) ...[
                  Divider(height: 30, color: isDark ? Colors.white10 : const Color(0xFFF3F4F6)),
                  ServiceWorkerTile(
                    workerName: service.workerName!,
                    workerImageUrl: service.workerImageUrl,
                    workerId: service.workerId,
                    isDark: isDark,
                  ),
                ],
                
                Divider(height: 40, color: isDark ? Colors.white10 : const Color(0xFFF3F4F6)),
                
                Text(
                  "DESCRIPCIÓN", 
                  style: TextStyle(
                    fontWeight: FontWeight.w900, 
                    fontSize: 13, 
                    letterSpacing: 1.2,
                    color: isDark ? Colors.white70 : Colors.black54
                  )
                ),
                
                const SizedBox(height: 14),
                
                Text(
                  service.description, 
                  style: TextStyle(
                    fontSize: 15, 
                    height: 1.6, 
                    color: isDark ? Colors.white60 : const Color(0xFF4B5563)
                  )
                ),
                
                const SizedBox(height: 30),

                // 2. EVIDENCIAS DEL TRABAJO
                if (service.status == JobStatus.matched ||
                    service.status == JobStatus.waiting_confirmation ||
                    service.status == JobStatus.completed ||
                    service.status == JobStatus.disputed)
                  WorkEvidenceSection(service: service),

                const SizedBox(height: 30),

                // 3. EL MAPA DE UBICACIÓN
                ServiceMapSection(
                  latitude: service.latitude,
                  longitude: service.longitude,
                  exactAddress: service.exactAddress,
                  themeColor: mainColor,
                ),
              ]
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryHeader(Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), 
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8)
      ), 
      child: Text(
        categoryName.toUpperCase(), 
        style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 11)
      )
    );
  }
}