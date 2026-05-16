import 'package:equatable/equatable.dart';

class MessageEntity extends Equatable {
  final String id;
  final String conversationId;
  final String senderId;
  final String content;
  final String messageType;
  final DateTime createdAt;
  final String status;

  const MessageEntity({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    required this.messageType,
    required this.createdAt,
    required this.status,
  });

  /// Getter centralizado para el formato de la hora (ej: "12:30 PM")
  String get displayTime {
    final localTime = createdAt.toLocal();
    final hour = localTime.hour > 12 
        ? localTime.hour - 12 
        : (localTime.hour == 0 ? 12 : localTime.hour);
    final minute = localTime.minute.toString().padLeft(2, '0');
    final period = localTime.hour >= 12 ? 'PM' : 'AM';
    return "$hour:$minute $period";
  }

  @override
  List<Object?> get props => [id, conversationId, senderId, content, messageType, createdAt, status];
}