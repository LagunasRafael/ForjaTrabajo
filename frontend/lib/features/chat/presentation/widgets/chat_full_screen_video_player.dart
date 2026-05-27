import 'package:flutter/material.dart';
import 'chat_video_player_widget.dart';

class ChatFullScreenVideoPlayer extends StatelessWidget {
  final String url;

  const ChatFullScreenVideoPlayer({super.key, required this.url});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ChatVideoPlayerWidget(url: url, isMe: false),
        ),
      ),
    );
  }
}
