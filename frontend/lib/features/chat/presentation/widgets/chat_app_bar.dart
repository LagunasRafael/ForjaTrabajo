import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../features/profile/presentation/screens/user_profile_screen.dart';

class ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  final dynamic service;
  final String? otherUserName;
  final String? otherUserAvatarUrl;
  final String? otherUserId;
  final String subtitlePrefix;
  final VoidCallback? onOpenDispute;
  final VoidCallback? onTapService;

  const ChatAppBar({
    super.key,
    this.service,
    this.otherUserName,
    this.otherUserAvatarUrl,
    this.otherUserId,
    this.subtitlePrefix = 'Postulante a',
    this.onOpenDispute,
    this.onTapService,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  Widget _buildInitial(String userName) {
    final initial = userName.isNotEmpty ? userName[0].toUpperCase() : 'U';
    return Center(
      child: Text(
        initial,
        style: const TextStyle(
            color: Color(0xFF4F46E5),
            fontWeight: FontWeight.bold,
            fontSize: 14),
      ),
    );
  }

  void _navigateToProfile(BuildContext context) {
    if (otherUserId != null && otherUserId!.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => UserProfileScreen(userId: otherUserId!),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final serviceTitle = service is Map ? service['title'] : 'Servicio';
    final userName = otherUserName ?? 'Usuario';
    final String avatarUrl = otherUserAvatarUrl?.trim() ?? '';
    final theme = Theme.of(context);

    return AppBar(
      backgroundColor: theme.colorScheme.surface,
      elevation: 0,
      shape: const Border(
        bottom: BorderSide(
          color: Color(0xFFE0E7FF),
          width: 1,
        ),
      ),
      centerTitle: false,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
        onPressed: () => Navigator.pop(context),
      ),
      title: GestureDetector(
        onTap: () => _navigateToProfile(context),
        child: Row(
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
                  ? CachedNetworkImage(
                      imageUrl: avatarUrl,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) =>
                          _buildInitial(userName),
                      placeholder: (context, url) => _buildInitial(userName),
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
                    style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  GestureDetector(
                    onTap: onTapService,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            "$subtitlePrefix \"$serviceTitle\"",
                            style: const TextStyle(
                              color: Color(0xFF4F46E5),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (onTapService != null) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.open_in_new,
                              size: 12, color: Color(0xFF4F46E5)),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        if (onOpenDispute != null)
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: theme.colorScheme.onSurface),
            onSelected: (value) {
              if (value == 'dispute') {
                onOpenDispute!();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'dispute',
                child: Row(
                  children: [
                    Icon(Icons.gavel, color: Colors.red, size: 20),
                    SizedBox(width: 8),
                    Text('Abrir Disputa',
                        style: TextStyle(
                            color: Colors.red, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }
}
