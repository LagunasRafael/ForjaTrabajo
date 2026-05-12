import 'package:flutter/material.dart';

class ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  final dynamic service;
  final String? otherUserName;
  final String? otherUserAvatarUrl;

  const ChatAppBar({
    super.key,
    this.service,
    this.otherUserName,
    this.otherUserAvatarUrl,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  Widget _buildInitial(String userName) {
    final initial = userName.isNotEmpty ? userName[0].toUpperCase() : 'U';
    return Center(
      child: Text(
        initial,
        style: const TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.bold, fontSize: 14),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final serviceTitle = service is Map ? service['title'] : 'Servicio';
    final userName = otherUserName ?? 'Usuario';
    final String avatarUrl = otherUserAvatarUrl?.trim() ?? '';

    return AppBar(
      backgroundColor: Colors.white,
      elevation: 1,
      centerTitle: false,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Color(0xFFEEF2FF),
              shape: BoxShape.circle,
            ),
            clipBehavior: Clip.hardEdge,
            child: avatarUrl.isNotEmpty && avatarUrl.startsWith('http')
                ? Image.network(
                    avatarUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => _buildInitial(userName),
                  )
                : _buildInitial(userName),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName,
                  style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  serviceTitle,
                  style: const TextStyle(color: Color(0xFF4F46E5), fontSize: 13, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
