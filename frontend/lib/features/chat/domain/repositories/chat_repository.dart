import 'package:forja_trabajo/features/chat/domain/entities/message_entity.dart';
import '../entities/chat_summary_entity.dart';

abstract class ChatRepository {
  Future<List<MessageEntity>> getChatHistory(String conversationId, {int skip = 0, int limit = 15});
  Future<Map<String, dynamic>> sendOffer(String conversationId, double amount);
  Future<Map<String, dynamic>> respondOffer(String messageId, String action);
  Future<String> getOrCreateConversation(String requestId);
  Future<List<ChatSummaryEntity>> getUserChats();
  Future<void> archiveChat(String conversationId, bool isArchived);
  Future<void> deleteChat(String conversationId);
  Future<String?> uploadChatMedia(String conversationId, String filePath);
  Future<void> openDispute(String conversationId, String reason);
  Future<void> markAsRead(String conversationId);
}