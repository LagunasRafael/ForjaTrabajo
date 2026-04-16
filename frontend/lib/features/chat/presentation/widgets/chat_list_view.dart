import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/chat_summary_entity.dart';
import '../providers/chat_list_provider.dart';
import 'chat_tile.dart'; 

class ChatListView extends ConsumerWidget {
  final List<ChatSummaryEntity> chats;
  final String emptyMessage;
  final bool isRefreshable;

  const ChatListView({
    super.key,
    required this.chats,
    required this.emptyMessage,
    this.isRefreshable = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Widget content;

    // 🧠 MAGIA DE SCROLL: Si está vacío, lo metemos en un ListView para permitir el "Pull to Refresh"
    if (chats.isEmpty) {
      content = ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.3), // Empuja el texto al centro
          Center(child: Text(emptyMessage, style: const TextStyle(color: Colors.grey))),
        ],
      );
    } else {
      content = ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: chats.length,
        itemBuilder: (context, index) => ChatTile(chat: chats[index]),
      );
    }

    if (isRefreshable) {
      return RefreshIndicator(
        onRefresh: () async {
          await ref.read(chatListProvider.notifier).refresh();
        },
        color: const Color(0xFF4F46E5),
        child: content,
      );
    }

    return content;
  }
}