import 'package:flutter/material.dart';
import 'package:forja_trabajo/features/services/domain/entities/service_entity.dart';
import 'package:forja_trabajo/features/services/presentation/screens/shared/utils/category_icon_helper.dart';
import 'package:forja_trabajo/features/services/presentation/screens/shared/detail/service_image_carousel.dart';
import 'package:forja_trabajo/features/services/presentation/screens/shared/detail/service_map_section.dart';

class ServiceDetailBody extends StatelessWidget {
  final ServiceEntity service;
  final String categoryName;
  final String authorName;
  final bool isOwner;
  final String? authorImageUrl;

  const ServiceDetailBody({
    super.key,
    required this.service,
    required this.categoryName,
    required this.authorName,
    required this.isOwner,
    this.authorImageUrl,
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
          // 1. EL CARRUSEL
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
                
                // 💰 El precio se queda verde porque es "dinero", pero brilla más en oscuro
                Text(
                  "\$${service.basePrice.toStringAsFixed(0)} MXN", 
                  style: TextStyle(
                    fontSize: 22, 
                    fontWeight: FontWeight.w900, 
                    color: isDark ? const Color(0xFF34D399) : const Color(0xFF10B981)
                  )
                ),

                // 🎨 Divisores adaptables
                Divider(height: 40, color: isDark ? Colors.white10 : const Color(0xFFF3F4F6)),
                
                _buildAuthorTile(mainColor, isDark),
                
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
                
                // 🎨 Texto de descripción adaptable
                Text(
                  service.description ?? "Sin descripción.", 
                  style: TextStyle(
                    fontSize: 15, 
                    height: 1.6, 
                    color: isDark ? Colors.white60 : const Color(0xFF4B5563)
                  )
                ),
                
                const SizedBox(height: 30),
                
                // 2. EL MAPA
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
        color: color.withOpacity(0.15), // Un poco más de opacidad para que resalte
        borderRadius: BorderRadius.circular(8)
      ), 
      child: Text(
        categoryName.toUpperCase(), 
        style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 11)
      )
    );
  }

  Widget _buildAuthorTile(Color color, bool isDark) {
    final initial = authorName.isNotEmpty ? authorName[0].toUpperCase() : 'U';

    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.2), // Fondo de color por si no hay foto
          ),
          child: ClipOval(
            child: (authorImageUrl != null && authorImageUrl!.isNotEmpty)
                ? Image.network(
                    authorImageUrl!,
                    fit: BoxFit.cover,
                    // Si el servidor falla o la imagen está corrupta, mostramos la letra
                    errorBuilder: (context, error, stackTrace) {
                      return Center(
                        child: Text(
                          initial, 
                          style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18)
                        ),
                      );
                    },
                  )
                : Center(
                    child: Text(
                      initial, 
                      style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18)
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Publicado por:", style: TextStyle(fontSize: 11, color: Colors.grey)),
              Text(
                authorName, 
                style: TextStyle(
                  fontWeight: FontWeight.bold, 
                  fontSize: 15,
                  color: isDark ? Colors.white : Colors.black87
                )
              ),
            ],
          ),
        ),
      ],
    );
  }
}