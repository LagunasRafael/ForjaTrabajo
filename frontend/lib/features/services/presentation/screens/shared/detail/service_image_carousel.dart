import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'full_screen_image_viewer.dart';

class ServiceImageCarousel extends StatefulWidget {
  final List<String> imageUrls;
  const ServiceImageCarousel({super.key, required this.imageUrls});

  @override
  State<ServiceImageCarousel> createState() => _ServiceImageCarouselState();
}

class _ServiceImageCarouselState extends State<ServiceImageCarousel> {
  int _currentIdx = 0;

  @override
  Widget build(BuildContext context) {
    final displayImages = widget.imageUrls.isNotEmpty 
        ? widget.imageUrls 
        : ['https://via.placeholder.com/600x400/e2e8f0/64748b?text=Sin+Evidencia+Visual.png'];

    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        CarouselSlider(
          options: CarouselOptions(
            viewportFraction: 1.0, 
            height: 250, 
            enableInfiniteScroll: false,
            onPageChanged: (i, _) => setState(() => _currentIdx = i)
          ),
          items: displayImages.asMap().entries.map((entry) {
            final index = entry.key;
            final url = entry.value;

            return GestureDetector(
              onTap: () => FullScreenImageViewer.open(context, displayImages, index),
              child: Hero(
                tag: url,
                child: Image.network(
                  url, 
                  fit: BoxFit.cover, 
                  width: double.infinity,
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
                ),
              ),
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
    );
  }
}