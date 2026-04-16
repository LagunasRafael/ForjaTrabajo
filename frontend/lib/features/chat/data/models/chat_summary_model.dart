import 'package:forja_trabajo/core/network/api_client.dart';
import '../../domain/entities/chat_summary_entity.dart';

class ChatSummaryModel extends ChatSummaryEntity {
  const ChatSummaryModel({
    required super.id,
    required super.name,
    required super.avatarUrl,
    required super.serviceName,
    required super.lastMessage,
    required super.time,
    required super.status,
    required super.myRole,
    super.hasUnread,
    super.isArchived,
  });

  factory ChatSummaryModel.fromJson(Map<String, dynamic> json) {
    String rawUrl = json['avatarUrl'] ?? '';
    if (rawUrl.isNotEmpty && !rawUrl.startsWith('http')) {
      rawUrl = "${ApiClient.baseUrl.replaceFirst('/api', '')}/$rawUrl";
    }

    return ChatSummaryModel(
      id: json['id'].toString(),
      name: json['name'] ?? 'Usuario',
      avatarUrl: rawUrl,
      serviceName: json['serviceName'] ?? 'Servicio',
      lastMessage: json['lastMessage'] ?? '',
      time: json['time'] ?? '',
      status: json['status'] ?? 'ACTIVO',
      myRole: json['myRole'] ?? 'client',
      hasUnread: json['hasUnread'] ?? false,
      isArchived: json['isArchived'] ?? false,
    );
  }
}