import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/chat_summary_entity.dart';
import '../providers/chat_list_provider.dart';
import '../screens/shared_chat_screen.dart';
import 'chat_context_menu.dart';

class ChatTile extends ConsumerWidget {
  final ChatSummaryEntity chat;

  const ChatTile({super.key, required this.chat});

  Widget _buildAvatarFallback(String name) {
    return Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : 'U',
        style: const TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.bold, fontSize: 20),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    Offset? tapPosition;

    return InkWell(
      onTapDown: (details) => tapPosition = details.globalPosition,
      onLongPress: () {
        if (tapPosition != null) {
          ChatContextMenu.show(context, ref, position: tapPosition!, chat: chat);
        }
      },
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SharedChatScreen(
              conversationId: chat.id,
              otherUserName: chat.name,
              otherUserAvatarUrl: chat.avatarUrl,
              otherUserId: chat.otherUserId,
              myRole: chat.myRole, 
              service: {
                'id': chat.serviceId,
                'title': chat.serviceName,
              },
            ),
          ),
        );
        ref.invalidate(chatListProvider);
      },
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.grey.shade200, width: 1.0),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0), // 👈 Un poco más de aire
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(color: Color(0xFFEEF2FF), shape: BoxShape.circle),
              clipBehavior: Clip.hardEdge,
              child: (chat.avatarUrl.isNotEmpty && chat.avatarUrl.startsWith('http'))
                  ? Image.network(
                      chat.avatarUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => _buildAvatarFallback(chat.name),
                    )
                  : _buildAvatarFallback(chat.name),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          chat.name, 
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: theme.colorScheme.onSurface),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(chat.time, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTapDown: (details) => tapPosition = details.globalPosition,
                        onTap: () {
                          if (tapPosition != null) {
                            ChatContextMenu.show(context, ref, position: tapPosition!, chat: chat);
                          }
                        },
                        child: const Icon(Icons.more_vert, color: Colors.grey, size: 18),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  // 🟢 SE ELIMINARON LOS ESTADOS, QUEDA EL SERVICIO LIMPIO
                  Text(
                    chat.serviceName, 
                    style: const TextStyle(fontSize: 13, color: Color(0xFF4F46E5), fontWeight: FontWeight.w600), 
                    overflow: TextOverflow.ellipsis
                  ),
                  const SizedBox(height: 4),
                  // 🟢 MENSAJE MÁS GRANDE (Pasó de 13 a 15)
                  Text(
                    chat.lastMessage, 
                    style: TextStyle(
                      color: chat.hasUnread ? theme.colorScheme.onSurface : theme.colorScheme.onSurface.withOpacity(0.6), 
                      fontSize: 15, // 👈 AQUÍ SE HIZO MÁS GRANDE
                      fontWeight: chat.hasUnread ? FontWeight.bold : FontWeight.normal,
                    ), 
                    overflow: TextOverflow.ellipsis, 
                    maxLines: 1, 
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}