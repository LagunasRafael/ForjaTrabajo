import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'chat_audio_player_widget.dart';
import 'chat_gallery_viewer_screen.dart';

class ChatBubble extends StatelessWidget {
  final String text;
  final bool isMe;
  final String? time;
  final String messageType;
  final String status;
  final VoidCallback? onRetry;
  final String? senderAvatarUrl;

  const ChatBubble({
    super.key,
    required this.text,
    required this.isMe,
    this.time,
    this.messageType = 'text',
    this.status = 'sent',
    this.onRetry,
    this.senderAvatarUrl,
  });

  Widget _buildSmallAvatar(ThemeData theme) {
    final url = senderAvatarUrl ?? '';
    if (url.isNotEmpty && url.startsWith('http')) {
      return CircleAvatar(
        radius: 16,
        backgroundColor: theme.colorScheme.primaryContainer,
        backgroundImage: NetworkImage(url),
        onBackgroundImageError: (_, __) {},
      );
    }
    return CircleAvatar(
      radius: 16,
      backgroundColor: theme.colorScheme.primaryContainer,
      child: const Icon(Icons.person, size: 18, color: Color(0xFF4F46E5)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (messageType == 'system') {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 40),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade300, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.blueGrey.shade900,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isMe) ...[
                _buildSmallAvatar(theme),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: GestureDetector(
                  onTap: () {
                    if (status == 'error' && onRetry != null) {
                      onRetry!();
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                    decoration: BoxDecoration(
                      color: isMe ? const Color(0xFF4F46E5) : theme.colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: isMe ? const Radius.circular(16) : Radius.zero,
                        bottomRight: isMe ? Radius.zero : const Radius.circular(16),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: isMe ? CrossAxisAlignment.start : CrossAxisAlignment.end,
                      children: [
                        _buildContent(context),
                        if (time != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  time!,
                                  style: TextStyle(
                                    color: isMe ? Colors.white70 : Colors.grey.shade500,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                if (isMe) ...[
                                  const SizedBox(width: 4),
                                  _buildStatusIcon(),
                                ]
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIcon() {
    if (status == 'sending') {
      return const SizedBox(
        width: 12,
        height: 12,
        child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.white54),
      );
    } else if (status == 'pending') {
      return const SizedBox.shrink();
    } else if (status == 'error') {
      return const Icon(Icons.refresh, size: 14, color: Colors.orangeAccent);
    } else {
      return const SizedBox.shrink();
    }
  }

  Widget _buildContent(BuildContext context) {
    final theme = Theme.of(context);
    if (messageType == 'gallery' || messageType == 'image' || messageType == 'video') {
      final urls = text.split(',');
      if (urls.length > 1) {
        return _buildGalleryGrid(urls, context);
      } else {
        final singleUrl = urls.first;
        final ext = singleUrl.split('?').first.toLowerCase();
        final isVideo = messageType == 'video' || ext.endsWith('.mp4') || ext.endsWith('.mov') || ext.endsWith('.mkv');
        if (isVideo) return _buildVideoPlaceholder();
        return _buildImagePlaceholder(overrideUrl: singleUrl, context: context);
      }
    } else if (messageType == 'audio') {
      return AudioPlayerWidget(url: text, isMe: isMe);
    } else if (messageType == 'location') {
      return _buildLocationPlaceholder(theme);
    } else {
      return Text(
        text,
        style: TextStyle(
          color: isMe ? Colors.white : theme.colorScheme.onSurface,
          fontSize: 15,
          height: 1.4,
        ),
      );
    }
  }

  void _openGallery(BuildContext context, List<String> urls, int initialIndex) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => GalleryViewerScreen(urls: urls, initialIndex: initialIndex),
    ));
  }

  Widget _buildGalleryGrid(List<String> urls, BuildContext context) {
    final int count = urls.length;

    if (count == 1) {
      final url = urls.first;
      final ext = url.split('?').first.toLowerCase();
      final isVideo = ext.endsWith('.mp4') || ext.endsWith('.mov') || ext.endsWith('.mkv');
      if (isVideo) return _buildVideoPlaceholder();
      return _buildImagePlaceholder(overrideUrl: url, size: 200, context: context);
    }

    const double spacing = 4.0;
    const double sizeBig = 244.0;
    const double sizeSmall = 120.0;

    if (count == 2) {
      return SizedBox(
        width: sizeBig,
        height: sizeSmall,
        child: Row(
          children: [
            Expanded(child: _buildGridThumbnail(urls[0], 0, urls, context)),
            const SizedBox(width: spacing),
            Expanded(child: _buildGridThumbnail(urls[1], 1, urls, context)),
          ],
        ),
      );
    }

    if (count == 3) {
      return SizedBox(
        width: sizeBig,
        height: sizeBig,
        child: Row(
          children: [
            Expanded(
              child: _buildGridThumbnail(urls[0], 0, urls, context, height: sizeBig),
            ),
            const SizedBox(width: spacing),
            Expanded(
              child: Column(
                children: [
                  Expanded(child: _buildGridThumbnail(urls[1], 1, urls, context)),
                  const SizedBox(height: spacing),
                  Expanded(child: _buildGridThumbnail(urls[2], 2, urls, context)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      width: sizeBig,
      height: sizeBig,
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(child: _buildGridThumbnail(urls[0], 0, urls, context)),
                const SizedBox(width: spacing),
                Expanded(child: _buildGridThumbnail(urls[1], 1, urls, context)),
              ],
            ),
          ),
          const SizedBox(height: spacing),
          Expanded(
            child: Row(
              children: [
                Expanded(child: _buildGridThumbnail(urls[2], 2, urls, context)),
                const SizedBox(width: spacing),
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _buildGridThumbnail(urls[3], 3, urls, context),
                      if (count > 4)
                        GestureDetector(
                          onTap: () => _openGallery(context, urls, 3),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                "+${count - 3}",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridThumbnail(
    String url,
    int index,
    List<String> urls,
    BuildContext context, {
    double? height,
  }) {
    final ext = url.split('?').first.toLowerCase();
    final isVideo = ext.endsWith('.mp4') || ext.endsWith('.mov') || ext.endsWith('.mkv');

    return GestureDetector(
      onTap: () {
        if (status == 'sending') return;
        _openGallery(context, urls, index);
      },
      child: Container(
        height: height,
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFF6366F1) : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            isVideo
                ? _buildVideoThumbnail()
                : _buildImageThumbnail(url),
            if (status == 'sending')
              Container(
                color: Colors.black45,
                child: const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.0,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoThumbnail() {
    return Container(
      color: Colors.black87,
      child: const Center(
        child: Icon(Icons.play_circle_outline, size: 36, color: Colors.white70),
      ),
    );
  }

  Widget _buildImageThumbnail(String url) {
    bool isUrl = url.startsWith('http');
    bool isLocal = url.startsWith('/') || url.startsWith('C:') || url.startsWith('var/') || url.startsWith('file://');

    if (isUrl) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(child: CircularProgressIndicator(color: isMe ? Colors.white : const Color(0xFF4F46E5)));
        },
        errorBuilder: (context, error, stackTrace) => const Center(
          child: Icon(Icons.broken_image, size: 24, color: Colors.grey),
        ),
      );
    } else if (isLocal) {
      final path = url.replaceFirst('file://', '');
      return Image.file(
        File(path),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const Center(
          child: Icon(Icons.broken_image, size: 24, color: Colors.grey),
        ),
      );
    } else {
      return const Center(child: Icon(Icons.image, size: 24, color: Colors.grey));
    }
  }

  Widget _buildImagePlaceholder({String? overrideUrl, double size = 200, required BuildContext context}) {
    final theme = Theme.of(context);
    final url = overrideUrl ?? text;
    bool isUrl = url.startsWith('http');
    bool isLocal = url.startsWith('/') || url.startsWith('C:') || url.startsWith('var/') || url.startsWith('file://');

    Widget imageWidget;
    if (isUrl) {
      imageWidget = Image.network(
        url,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(child: CircularProgressIndicator(color: isMe ? Colors.white : const Color(0xFF4F46E5)));
        },
        errorBuilder: (context, error, stackTrace) => Center(child: Icon(Icons.broken_image, size: 40, color: isMe ? Colors.white : Colors.grey)),
      );
    } else if (isLocal) {
      final path = url.replaceFirst('file://', '');
      imageWidget = Image.file(
        File(path),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Center(child: Icon(Icons.broken_image, size: 40, color: isMe ? Colors.white : Colors.grey)),
      );
    } else {
      imageWidget = Center(child: Icon(Icons.image, size: 40, color: isMe ? Colors.white : Colors.grey));
    }

    return GestureDetector(
      onTap: () {
        if (status == 'sending') return;
        if (!isUrl && !isLocal) return;
        _openGallery(context, [url], 0);
      },
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFF6366F1) : theme.colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
        ),
        clipBehavior: Clip.hardEdge,
        child: Stack(
          fit: StackFit.expand,
          children: [
            imageWidget,
            if (status == 'sending')
              Container(
                color: Colors.black45,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Enviando...",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoPlaceholder({String? overrideUrl, double size = 200}) {
    final url = overrideUrl ?? text.split(',').first.trim();
    return GestureDetector(
      onTap: () async {
        if (status == 'sending') return;
        if (url.startsWith('http')) {
          final uri = Uri.parse(url);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        }
      },
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(12),
        ),
        clipBehavior: Clip.hardEdge,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.play_circle_outline, size: 50, color: Colors.white),
                const SizedBox(height: 4),
                Text(
                  'Toca para reproducir',
                  style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11),
                ),
              ],
            ),
            if (status == 'sending')
              Container(
                color: Colors.black54,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Enviando...",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationPlaceholder(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 200,
          height: 120,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
            image: const DecorationImage(
              image: AssetImage('assets/images/map_placeholder.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: Center(
            child: Icon(Icons.location_on, size: 40, color: Colors.red.shade400),
          ),
        ),
        const SizedBox(height: 8),
        Text("Ubicación compartida", style: TextStyle(color: isMe ? Colors.white : Colors.black87, fontSize: 13, fontStyle: FontStyle.italic)),
      ],
    );
  }
}
