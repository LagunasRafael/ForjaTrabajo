import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:url_launcher/url_launcher.dart'; 
import 'package:forja_trabajo/features/services/domain/entities/service_entity.dart';

class ServiceDetailBody extends StatefulWidget {
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
  State<ServiceDetailBody> createState() => _ServiceDetailBodyState();
}

class _ServiceDetailBodyState extends State<ServiceDetailBody> {
  int _currentIdx = 0;
  
  // 🚀 ADIÓS A LAS IMÁGENES FALSAS DE UNSPLASH

  Future<void> _abrirGoogleMaps() async {
    final lat = widget.service.latitude;
    final lng = widget.service.longitude;

    if (lat == null || lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Este servicio no tiene ubicación GPS exacta registrada.")),
      );
      return;
    }

    final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No se pudo abrir la aplicación de mapas.")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mainColor = _getCategoryColor(widget.categoryName);

    // 👇 1. OBTENEMOS LAS IMÁGENES REALES DEL SERVICIO
    // Si no subió ninguna foto, le ponemos una imagen de "Sin Imágenes" por defecto.
    final List<String> displayImages = widget.service.imageUrls.isNotEmpty 
        ? widget.service.imageUrls 
        : ['https://placehold.co/600x400/e2e8f0/64748b?text=Sin+Evidencia+Visual'];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              CarouselSlider(
                options: CarouselOptions(
                  viewportFraction: 1.0, 
                  height: 250, 
                  enableInfiniteScroll: false,
                  onPageChanged: (i, _) => setState(() => _currentIdx = i)
                ),
                // 👇 2. PINTAMOS LAS IMÁGENES DEL BACKEND
                items: displayImages.map((url) {
                  return Image.network(
                    url, 
                    fit: BoxFit.cover, 
                    width: double.infinity,
                    // ESCUDO: Si la URL del backend falla, muestra esto en vez de error rojo
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey.shade200,
                        child: const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.broken_image, color: Colors.grey, size: 40),
                              SizedBox(height: 8),
                              Text("Imagen no disponible", style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }).toList(),
              ),
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), borderRadius: BorderRadius.circular(20)),
                child: Text("${_currentIdx + 1}/${displayImages.length}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ),
          
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, 
              children: [
                _buildCategoryHeader(mainColor),
                const SizedBox(height: 12),
                Text(widget.service.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text("\$${widget.service.basePrice.toStringAsFixed(0)} MXN", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: const Color(0xFF10B981))),
                
                const Divider(height: 40, color: Color(0xFFF3F4F6)),
                _buildAuthorTile(mainColor),
                const Divider(height: 40, color: Color(0xFFF3F4F6)),
                
                const Text("DESCRIPCIÓN", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1.2)),
                const SizedBox(height: 14),
                Text(widget.service.description ?? "Sin descripción.", style: const TextStyle(fontSize: 15, height: 1.5, color: const Color(0xFF4B5563))),
                
                const SizedBox(height: 30),
                _buildMapSection(mainColor),
              ]
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryHeader(Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween, 
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), 
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), 
          child: Text(widget.categoryName.toUpperCase(), style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 11))
        ),
      ]
    );
  }

  Widget _buildAuthorTile(Color color) {
    return Row(
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: color.withOpacity(0.2), 
          backgroundImage: (widget.authorImageUrl != null && widget.authorImageUrl!.isNotEmpty) 
              ? NetworkImage(widget.authorImageUrl!) 
              : null,
          child: (widget.authorImageUrl == null || widget.authorImageUrl!.isEmpty)
              ? Text(widget.authorName.isNotEmpty ? widget.authorName[0].toUpperCase() : 'U', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18))
              : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Publicado por:", style: TextStyle(fontSize: 11, color: Colors.grey)),
              Text(widget.authorName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMapSection(Color color) {
    final bool hasLocation = widget.service.latitude != null && widget.service.longitude != null;

    final String displayAddress = (widget.service.exactAddress != null && widget.service.exactAddress!.isNotEmpty) 
        ? widget.service.exactAddress! 
        : "Dirección no especificada";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("UBICACIÓN APROXIMADA", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1.2)),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(Icons.location_on, size: 16, color: color),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      displayAddress, 
                      style: TextStyle(fontWeight: FontWeight.w800, color: color),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        GestureDetector(
          onTap: _abrirGoogleMaps,
          child: Container(
            height: 180, width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.blue[50], 
              borderRadius: BorderRadius.circular(16), 
              image: DecorationImage(
                image: const NetworkImage("https://placehold.co/600x300/e0e7ff/4f46e5?text=Toca+para+abrir+Google+Maps"), 
                fit: BoxFit.cover,
                colorFilter: hasLocation ? null : ColorFilter.mode(Colors.grey.shade300, BlendMode.saturation)
              )
            ),
            child: hasLocation 
                ? Center(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: color, shape: BoxShape.circle, boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)]),
                      child: const Icon(Icons.map_rounded, color: Colors.white, size: 32),
                    ),
                  )
                : const Center(child: Text("Ubicación GPS no disponible", style: TextStyle(fontWeight: FontWeight.bold))),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          "La dirección exacta será revelada una vez aceptado el trabajo. Toca el mapa para ver la zona.",
          style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey, fontSize: 12),
        ),
      ]
    );
  }

  Color _getCategoryColor(String cat) {
    final t = cat.toLowerCase();
    if (t.contains('plom') || t.contains('font')) return const Color(0xFF4F46E5); 
    if (t.contains('elec')) return Colors.orange;
    return const Color(0xFF4F46E5);
  }
}