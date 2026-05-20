import 'package:flutter/material.dart';
import 'package:forja_trabajo/features/profile/presentation/screens/user_profile_screen.dart';

class ServiceAuthorTile extends StatelessWidget {
  final String authorName;
  final String? authorImageUrl;
  final String? authorId;
  final bool isOwner;
  final Color themeColor;
  final bool isDark;

  const ServiceAuthorTile({
    super.key,
    required this.authorName,
    required this.authorImageUrl,
    required this.authorId,
    required this.isOwner,
    required this.themeColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final initial = authorName.isNotEmpty ? authorName[0].toUpperCase() : 'U';

    return GestureDetector(
      onTap: () {
        if (authorId != null && !isOwner) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => UserProfileScreen(userId: authorId!),
            ),
          );
        }
      },
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: themeColor.withOpacity(0.2),
            ),
            child: ClipOval(
              child: (authorImageUrl != null && authorImageUrl!.isNotEmpty)
                  ? Image.network(
                      authorImageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Text(
                            initial,
                            style: TextStyle(color: themeColor, fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                        );
                      },
                    )
                  : Center(
                      child: Text(
                        initial,
                        style: TextStyle(color: themeColor, fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Publicado por:", style: TextStyle(fontSize: 11, color: Colors.grey)),
                Text(
                  authorName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ServiceWorkerTile extends StatelessWidget {
  final String workerName;
  final String? workerImageUrl;
  final String? workerId;
  final bool isDark;

  const ServiceWorkerTile({
    super.key,
    required this.workerName,
    required this.workerImageUrl,
    required this.workerId,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final initial = workerName.isNotEmpty ? workerName[0].toUpperCase() : 'W';

    return GestureDetector(
      onTap: () {
        if (workerId != null) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => UserProfileScreen(userId: workerId!),
            ),
          );
        }
      },
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF10B981).withOpacity(0.2),
            ),
            child: ClipOval(
              child: (workerImageUrl != null && workerImageUrl!.isNotEmpty)
                  ? Image.network(
                      workerImageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Text(
                            initial,
                            style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                        );
                      },
                    )
                  : Center(
                      child: Text(
                        initial,
                        style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Realizado por:", style: TextStyle(fontSize: 11, color: Colors.grey)),
                Text(
                  workerName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.check_circle, size: 12, color: Color(0xFF10B981)),
                SizedBox(width: 4),
                Text(
                  "Asignado",
                  style: TextStyle(color: Color(0xFF10B981), fontSize: 10, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
