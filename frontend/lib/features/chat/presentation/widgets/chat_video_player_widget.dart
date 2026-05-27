import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

class ChatVideoPlayerWidget extends StatefulWidget {
  final String url;
  final bool isMe;

  const ChatVideoPlayerWidget({
    super.key,
    required this.url,
    required this.isMe,
  });

  @override
  State<ChatVideoPlayerWidget> createState() => _ChatVideoPlayerWidgetState();
}

class _ChatVideoPlayerWidgetState extends State<ChatVideoPlayerWidget> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _isInitialized = false;
  bool _hasError = false;
  bool _playRequested = false;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    try {
      final isLocal = widget.url.startsWith('/') ||
          widget.url.startsWith('C:') ||
          widget.url.startsWith('var/') ||
          widget.url.startsWith('file://');

      _videoController = isLocal
          ? VideoPlayerController.file(
              File(widget.url.replaceFirst('file://', '')),
            )
          : VideoPlayerController.networkUrl(Uri.parse(widget.url));

      await _videoController!.initialize();

      if (!mounted) {
        _videoController!.dispose();
        return;
      }

      setState(() => _isInitialized = true);
    } catch (e) {
      if (mounted) {
        setState(() => _hasError = true);
      }
    }
  }

  void _play() {
    if (_videoController == null || _playRequested) return;
    setState(() => _playRequested = true);
    _chewieController = ChewieController(
      videoPlayerController: _videoController!,
      autoPlay: true,
      looping: false,
      allowPlaybackSpeedChanging: false,
      allowMuting: false,
      showControlsOnInitialize: true,
      fullScreenByDefault: false,
      materialProgressColors: ChewieProgressColors(
        playedColor: widget.isMe ? Colors.white : const Color(0xFF4F46E5),
        handleColor: widget.isMe ? Colors.white : const Color(0xFF4F46E5),
        backgroundColor: Colors.grey.shade400,
        bufferedColor: Colors.grey.shade300,
      ),
    );
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.broken_image, size: 40, color: Colors.white38),
              SizedBox(height: 8),
              Text(
                'Error al cargar video',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    if (!_isInitialized) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white54,
            ),
          ),
        ),
      );
    }

    if (!_playRequested) {
      return _buildThumbnail();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: AspectRatio(
        aspectRatio: _videoController!.value.aspectRatio,
        child: Chewie(controller: _chewieController!),
      ),
    );
  }

  Widget _buildThumbnail() {
    final size = _videoController!.value.size;
    final aspectRatio = size.width / size.height;
    final thumbHeight = aspectRatio > 1.5 ? 200.0 : 200.0;

    return GestureDetector(
      onTap: _play,
      child: Container(
        height: thumbHeight,
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(12),
        ),
        clipBehavior: Clip.hardEdge,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: VideoPlayer(_videoController!),
            ),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.black26,
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.play_circle_outline,
                  size: 50,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
                const SizedBox(height: 4),
                Text(
                  'Toca para reproducir',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
