import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ChatMediaPreview extends StatelessWidget {
  final List<XFile> mediaList;
  final List<String> mediaTypes;
  final List<Duration?>? mediaDurations;
  final Function(int) onRemove;

  const ChatMediaPreview({
    super.key,
    required this.mediaList,
    required this.mediaTypes,
    this.mediaDurations,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    if (mediaList.isEmpty) return const SizedBox.shrink();

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: mediaList.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final media = mediaList[index];
          final type = mediaTypes[index];

          return Stack(
            alignment: Alignment.topRight,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8, right: 8),
                height: 100,
                width: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey.shade200,
                  image: type == 'image'
                      ? DecorationImage(
                          image: FileImage(File(media.path)),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: type == 'video'
                    ? const Center(child: Icon(Icons.videocam, size: 40, color: Colors.grey))
                    : type == 'audio'
                        ? Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Colors.blue.shade100, Colors.blue.shade50],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                const Icon(Icons.mic, size: 40, color: Color(0xFF4F46E5)),
                                if (mediaDurations != null && mediaDurations![index] != null)
                                  Positioned(
                                    bottom: 8,
                                    child: Text(
                                      _formatDuration(mediaDurations![index]!),
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF4F46E5),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          )
                        : null,
              ),
              Positioned(
                top: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () => onRemove(index),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                       color: Colors.red,
                       shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, color: Colors.white, size: 16),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return "$minutes:${seconds.toString().padLeft(2, '0')}";
  }
}
