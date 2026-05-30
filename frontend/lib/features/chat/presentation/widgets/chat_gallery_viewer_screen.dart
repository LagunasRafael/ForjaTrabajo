import 'dart:io';
import 'package:flutter/material.dart';
import 'chat_video_player_widget.dart';

class GalleryViewerScreen extends StatefulWidget {
  final List<String> urls;
  final int initialIndex;

  const GalleryViewerScreen({super.key, required this.urls, required this.initialIndex});

  @override
  State<GalleryViewerScreen> createState() => _GalleryViewerScreenState();
}

class _GalleryViewerScreenState extends State<GalleryViewerScreen> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        title: Text(
          "${_currentIndex + 1} de ${widget.urls.length}",
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.urls.length,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        itemBuilder: (context, index) {
          final url = widget.urls[index];
          final ext = url.split('?').first.toLowerCase();
          final isVideo = ext.endsWith('.mp4') || ext.endsWith('.mov') || ext.endsWith('.mkv');

          if (isVideo) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ChatVideoPlayerWidget(url: url, isMe: false),
              ),
            );
          } else {
            final isUrl = url.startsWith('http');
            return InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 4.0,
              child: Center(
                child: isUrl
                    ? Image.network(url, fit: BoxFit.contain)
                    : Image.file(File(url.replaceFirst('file://', '')), fit: BoxFit.contain),
              ),
            );
          }
        },
      ),
    );
  }
}
