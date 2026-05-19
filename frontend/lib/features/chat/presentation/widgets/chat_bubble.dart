import 'dart:io';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:url_launcher/url_launcher.dart';

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
    // 📢 ESTILO PARA MENSAJES DE SISTEMA (ADMIN / DISPUTAS)
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
              
              // LA BURBUJA DE TEXTO
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
                      // Yo: Morado | El otro: Blanco
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
                      // Hora a la izquierda si soy yo, a la derecha si es el otro
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
                            )
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
      return const Icon(Icons.check, size: 14, color: Colors.white54);
    }
  }

  Widget _buildContent(BuildContext context) {
    final theme = Theme.of(context);
    if (messageType == 'gallery' || messageType == 'image' || messageType == 'video') {
       final urls = text.split(',');
       if (urls.length > 1) {
          return _buildGalleryGrid(urls, theme);
       } else {
          final singleUrl = urls.first;
          final ext = singleUrl.split('?').first.toLowerCase();
          final isVideo = messageType == 'video' || ext.endsWith('.mp4') || ext.endsWith('.mov') || ext.endsWith('.mkv');
          if (isVideo) return _buildVideoPlaceholder(theme: theme);
          return _buildImagePlaceholder(overrideUrl: singleUrl, theme: theme);
       }
    } else if (messageType == 'audio') {
      return _buildAudioPlaceholder();
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

  Widget _buildGalleryGrid(List<String> urls, ThemeData theme) {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: urls.map((url) {
         final ext = url.split('?').first.toLowerCase();
         final isVideo = ext.endsWith('.mp4') || ext.endsWith('.mov') || ext.endsWith('.mkv');
         if (isVideo) {
            return _buildVideoPlaceholder(size: 100, theme: theme);
         } else {
            return _buildImagePlaceholder(overrideUrl: url, size: 100, theme: theme);
         }
      }).toList(),
    );
  }

  Widget _buildImagePlaceholder({String? overrideUrl, double size = 200, required ThemeData theme}) {
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

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isMe ? const Color(0xFF6366F1) : theme.colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.hardEdge,
      child: imageWidget,
    );
  }

  Widget _buildAudioPlaceholder() {
    return _AudioPlayerWidget(url: text, isMe: isMe);
  }

  Widget _buildVideoPlaceholder({double size = 200, required ThemeData theme}) {
    return GestureDetector(
      onTap: () async {
        final url = text.split(',').first.trim();
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
        child: Column(
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
            )
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

class _AudioPlayerWidget extends StatefulWidget {
  final String url;
  final bool isMe;

  const _AudioPlayerWidget({required this.url, required this.isMe});

  @override
  State<_AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<_AudioPlayerWidget> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _isLoading = true; 

  @override
  void initState() {
    super.initState();
    _initAudio();
  }

  Future<void> _initAudio() async {
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });

    _audioPlayer.onDurationChanged.listen((newDuration) {
      if (mounted) {
        setState(() {
          _duration = newDuration;
          _isLoading = false; 
        });
      }
    });

    _audioPlayer.onPositionChanged.listen((newPosition) {
      if (mounted) {
        setState(() {
          _position = newPosition;
        });
      }
    });

    bool isLocal = widget.url.startsWith('/') || 
                   widget.url.startsWith('C:') || 
                   widget.url.startsWith('var/') || 
                   widget.url.startsWith('file://');
    try {
      if (isLocal) {
        await _audioPlayer.setSourceDeviceFile(widget.url.replaceFirst('file://', ''));
      } else {
        await _audioPlayer.setSourceUrl(widget.url);
      }
      
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted && _isLoading) {
          setState(() => _isLoading = false);
        }
      });
    } catch (e) {
      print("🚨 Error precargando audio: $e");
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return "$minutes:${seconds.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(
              _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
              color: widget.isMe ? Colors.white : const Color(0xFF4F46E5),
              size: 36,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () async {
              if (_isPlaying) {
                await _audioPlayer.pause();
              } else {
                bool isLocal = widget.url.startsWith('/') || 
                               widget.url.startsWith('C:') || 
                               widget.url.startsWith('var/') || 
                               widget.url.startsWith('file://');
                if (isLocal) {
                  await _audioPlayer.play(DeviceFileSource(widget.url.replaceFirst('file://', '')));
                } else {
                  await _audioPlayer.play(UrlSource(widget.url));
                }
              }
            },
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 120,
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                trackHeight: 2,
              ),
              child: Slider(
                min: 0,
                max: _duration.inMilliseconds.toDouble() > 0 
                    ? _duration.inMilliseconds.toDouble() 
                    : 1,
                value: _position.inMilliseconds.toDouble().clamp(
                  0, 
                  _duration.inMilliseconds.toDouble() > 0 
                      ? _duration.inMilliseconds.toDouble() 
                      : 1
                ),
                activeColor: widget.isMe ? Colors.white : const Color(0xFF4F46E5),
                inactiveColor: widget.isMe ? Colors.white54 : Colors.grey.shade300,
                onChanged: (value) async {
                  await _audioPlayer.seek(Duration(milliseconds: value.toInt()));
                },
              ),
            ),
          ),
          const SizedBox(width: 4),
          SizedBox(
            width: 40,
            child: Text(
              _isLoading 
                  ? "..." 
                  : (_isPlaying 
                      ? _formatDuration(_position) 
                      : _formatDuration(_duration)),
              style: TextStyle(
                color: widget.isMe ? Colors.white : Colors.black87, 
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}