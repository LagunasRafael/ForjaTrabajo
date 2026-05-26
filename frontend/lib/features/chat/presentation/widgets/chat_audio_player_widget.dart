import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class AudioPlayerWidget extends StatefulWidget {
  final String url;
  final bool isMe;

  const AudioPlayerWidget({super.key, required this.url, required this.isMe});

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
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
                      : 1,
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
