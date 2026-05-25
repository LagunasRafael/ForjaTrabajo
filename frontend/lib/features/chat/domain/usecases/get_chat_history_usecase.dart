import '../repositories/chat_repository.dart';
import '../entities/message_entity.dart';

class GetChatHistoryUseCase {
  final ChatRepository repository;

  GetChatHistoryUseCase(this.repository);

  Future<List<MessageEntity>> call(String conversationId, {int skip = 0, int limit = 15}) async {
    return await repository.getChatHistory(conversationId, skip: skip, limit: limit);
  }
}