import 'package:forja_trabajo/features/chat/domain/repositories/chat_repository.dart';

class StartChatUseCase {
  final ChatRepository repository;
  StartChatUseCase(this.repository);

  Future<String> call(String requestId) async {
    return await repository.getOrCreateConversation(requestId);
  }
}