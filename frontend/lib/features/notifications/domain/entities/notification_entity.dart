class NotificationEntity {
  final String id;
  final String userId;
  final String title;
  final String? body;
  final String type;
  final String? referenceId;
  final bool isRead;
  final DateTime createdAt;

  NotificationEntity({
    required this.id,
    required this.userId,
    required this.title,
    this.body,
    required this.type,
    this.referenceId,
    required this.isRead,
    required this.createdAt,
  });

  NotificationEntity copyWith({
    String? id,
    String? userId,
    String? title,
    String? body,
    String? type,
    String? referenceId,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return NotificationEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      referenceId: referenceId ?? this.referenceId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
