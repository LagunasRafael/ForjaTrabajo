import 'package:equatable/equatable.dart';

class ChatSummaryEntity extends Equatable {
  final String id;
  final String name;
  final String avatarUrl;
  final String serviceName;
  final String lastMessage;
  final String time;
  final String status;
  final String myRole;
  final String otherUserId;
  final bool hasUnread;
  final bool isArchived;

  const ChatSummaryEntity({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.serviceName,
    required this.lastMessage,
    required this.time,
    required this.status,
    required this.myRole,
    required this.otherUserId,
    this.hasUnread = false,
    this.isArchived = false,
  });

  ChatSummaryEntity copyWith({
    String? id,
    String? name,
    String? avatarUrl,
    String? serviceName,
    String? lastMessage,
    String? time,
    String? status,
    String? myRole,
    String? otherUserId,
    bool? hasUnread,
    bool? isArchived,
  }) {
    return ChatSummaryEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      serviceName: serviceName ?? this.serviceName,
      lastMessage: lastMessage ?? this.lastMessage,
      time: time ?? this.time,
      status: status ?? this.status,
      myRole: myRole ?? this.myRole,
      otherUserId: otherUserId ?? this.otherUserId,
      hasUnread: hasUnread ?? this.hasUnread,
      isArchived: isArchived ?? this.isArchived,
    );
  }

  @override
  List<Object?> get props => [id, name, avatarUrl, serviceName, lastMessage, time, status, myRole, otherUserId, hasUnread, isArchived];
}

