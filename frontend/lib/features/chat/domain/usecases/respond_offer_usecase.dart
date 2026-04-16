import '../repositories/chat_repository.dart';

class RespondOfferUseCase {
  final ChatRepository repository;

  RespondOfferUseCase(this.repository);

  Future<void> call(String messageId, String action) async {
    return await repository.respondOffer(messageId, action);
  }
}