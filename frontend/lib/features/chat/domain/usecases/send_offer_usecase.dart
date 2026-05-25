import '../repositories/chat_repository.dart';

class SendOfferUseCase {
  final ChatRepository repository;

  SendOfferUseCase(this.repository);

  Future<Map<String, dynamic>> call(String conversationId, double amount) async {
    return await repository.sendOffer(conversationId, amount);
  }
}