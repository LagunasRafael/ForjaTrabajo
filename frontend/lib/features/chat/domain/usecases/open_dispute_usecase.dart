import '../entities/message_entity.dart';
import '../repositories/chat_repository.dart';

class OpenDisputeUseCase {
  final ChatRepository repository;

  OpenDisputeUseCase(this.repository);

  Future<MessageEntity> call(String conversationId, String reason) async {
    return await repository.openDispute(conversationId, reason);
  }
}
