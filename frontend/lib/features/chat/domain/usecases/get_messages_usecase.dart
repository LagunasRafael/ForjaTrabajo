import 'package:forja_trabajo/features/chat/domain/repositories/chat_repository.dart';
import 'package:forja_trabajo/features/chat/domain/entities/message_entity.dart';

class GetChatHistoryUseCase {
  final ChatRepository repository;
  GetChatHistoryUseCase(this.repository);

  // Mantenemos la firma temporal por compatibilidad si se usa,
  // Aunque GetChatHistoryUseCase ya está definido en otro archivo
  Future<List<MessageEntity>> call(String conversationId) async {
    return await repository.getChatHistory(conversationId);
  }
}