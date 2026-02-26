import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:forja_trabajo/features/services/domain/entities/service_entity.dart';

class ServiceDetailBody extends StatefulWidget {
  final ServiceEntity service;
  final String categoryName;
  final String authorName;
  final bool isOwner;

  const ServiceDetailBody({
    super.key,
    required this.service,
    required this.categoryName,
    required this.authorName,
    required this.isOwner,
  });

  @override
  State<ServiceDetailBody> createState() => _ServiceDetailBodyState();
}

class _ServiceDetailBodyState extends State<ServiceDetailBody> {
  int _currentIdx = 0;
  final List<String> _imgs = [
    'https://images.unsplash.com/photo-1584622050111-993a426fbf0a?q=80&w=1000',
    'https://content.instructables.com/ORIG/F6I/O71K/H1L54G3L/F6IO71KH1L54G3L.jpg',
  ];

  @override
  Widget build(BuildContext context) {
    final mainColor = _getCategoryColor(widget.categoryName);

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 300, pinned: true, backgroundColor: mainColor,
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              fit: StackFit.expand,
              children: [
                CarouselSlider(
                  options: CarouselOptions(viewportFraction: 1.0, height: 350, onPageChanged: (i, _) => setState(() => _currentIdx = i)),
                  items: _imgs.map((u) => Image.network(u, fit: BoxFit.cover, width: double.infinity)).toList(),
                ),
                Positioned(bottom: 20, right: 20, child: Text("${_currentIdx + 1}/${_imgs.length}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _buildCategoryHeader(mainColor),
              const SizedBox(height: 15),
              Text(widget.service.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              Text("\$${widget.service.basePrice.toStringAsFixed(0)} MXN", style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.green)),
              const Divider(height: 40),
              _buildAuthorTile(mainColor),
              const Divider(height: 40),
              const Text("DESCRIPCIÓN", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 10),
              Text(widget.service.description ?? "Sin descripción.", style: const TextStyle(fontSize: 15, height: 1.6)),
              const SizedBox(height: 30),
              _buildMapSection(mainColor),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryHeader(Color color) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Text(widget.categoryName.toUpperCase(), style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11))),
      const Text("Hace poco", style: TextStyle(color: Colors.grey, fontSize: 12)),
    ]);
  }

  Widget _buildAuthorTile(Color color) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(backgroundColor: Colors.grey[200], child: Text(widget.authorName[0], style: TextStyle(color: color, fontWeight: FontWeight.bold))),
      title: const Text("Publicado por:", style: TextStyle(fontSize: 12, color: Colors.grey)),
      subtitle: Text(widget.authorName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
    );
  }

  Widget _buildMapSection(Color color) {
    return Column(children: [
      Row(children: [Icon(Icons.location_on, size: 16, color: color), const SizedBox(width: 4), Text(widget.service.exactAddress ?? "Ubicación remota", style: const TextStyle(fontWeight: FontWeight.bold))]),
      const SizedBox(height: 10),
      Container(
        height: 180, width: double.infinity,
        decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(16), image: const DecorationImage(image: NetworkImage("https://placehold.co/600x400/png?text=Mapa+Ubicacion"), fit: BoxFit.cover)),
      ),
    ]);
  }

  Color _getCategoryColor(String cat) {
    final t = cat.toLowerCase();
    if (t.contains('plom')) return Colors.blue;
    if (t.contains('elec')) return Colors.orange;
    return Colors.indigo;
  }
}