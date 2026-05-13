import '../repositories/chat_repository.dart';

class OpenDisputeUseCase {
  final ChatRepository repository;

  OpenDisputeUseCase(this.repository);

  Future<void> call(String conversationId, String reason) async {
    return await repository.openDispute(conversationId, reason);
  }
}
