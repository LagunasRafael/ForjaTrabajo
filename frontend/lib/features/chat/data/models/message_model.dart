import 'package:forja_trabajo/features/chat/domain/entities/message_entity.dart';

class MessageModel extends MessageEntity {
  const MessageModel({
    required super.id,
    required super.conversationId,
    required super.senderId,
    required super.content,
    required super.messageType,
    required super.createdAt,
    required super.status,
  });

  /// Crea un `MessageModel` a partir de un JSON (Map)
  factory MessageModel.fromJson(Map<String, dynamic> json) {
    // 💡 Helper robusto para parsear fechas
    DateTime parsedDate;
    final rawTime = json['created_at'] ?? json['timestamp'] ?? json['date'] ?? json['sent_at'];

    if (rawTime != null && rawTime.toString().trim().isNotEmpty) {
      try {
        if (rawTime is int || int.tryParse(rawTime.toString()) != null) {
          int timeInt = rawTime is int ? rawTime : int.parse(rawTime.toString());
          if (timeInt.toString().length <= 10) timeInt *= 1000;
          parsedDate = DateTime.fromMillisecondsSinceEpoch(timeInt).toUtc();
        } else {
          parsedDate = DateTime.parse(rawTime.toString()).toUtc();
        }
      } catch (e) {
        parsedDate = DateTime.now().toUtc();
      }
    } else {
      parsedDate = DateTime.now().toUtc();
    }

    return MessageModel(
      id: json['id']?.toString() ?? '',
      conversationId: json['conversation_id']?.toString() ?? json['conversationId']?.toString() ?? '',
      senderId: json['sender_id']?.toString() ?? json['senderId']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      messageType: json['message_type']?.toString() ?? json['type']?.toString() ?? 'text',
      createdAt: parsedDate,
      status: ((json['message_type']?.toString() ?? json['type']?.toString()) != 'offer' && json['status']?.toString() == 'pending')
          ? 'sent'
          : (json['status']?.toString() ?? 'sent'),
    );
  }

  /// Convierte el `MessageModel` de vuelta a Map JSON si hace falta enviarlo
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversation_id': conversationId,
      'sender_id': senderId,
      'content': content,
      'message_type': messageType,
      'created_at': createdAt.toIso8601String(),
      'status': status,
    };
  }

  /// Helper para convertir desde Entity a Model si es necesario
  factory MessageModel.fromEntity(MessageEntity entity) {
    return MessageModel(
      id: entity.id,
      conversationId: entity.conversationId,
      senderId: entity.senderId,
      content: entity.content,
      messageType: entity.messageType,
      createdAt: entity.createdAt,
      status: entity.status,
    );
  }
}