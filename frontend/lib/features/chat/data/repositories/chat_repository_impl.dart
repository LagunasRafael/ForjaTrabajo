import '../../domain/entities/message_entity.dart';
import '../../domain/entities/chat_summary_entity.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/chat_remote_datasource.dart';
import '../models/message_model.dart';
import '../models/chat_summary_model.dart'; 

class ChatRepositoryImpl implements ChatRepository {
  final ChatRemoteDataSource remoteDataSource;

  ChatRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<MessageEntity>> getChatHistory(String conversationId, {int skip = 0, int limit = 15}) async {
    final List<dynamic> rawData = await remoteDataSource.getHistory(conversationId, skip: skip, limit: limit);
    return rawData.map<MessageEntity>((json) => MessageModel.fromJson(json)).toList();
  }

  @override
  Future<String> getOrCreateConversation(String requestId) async {
    return await remoteDataSource.startOrGetChat(requestId);
  }

  @override
  Future<List<ChatSummaryEntity>> getUserChats() async {
    final List<dynamic> rawData = await remoteDataSource.getUserChats();
    return rawData.map((json) => ChatSummaryModel.fromJson(json)).toList();
  }

  @override
  Future<void> sendOffer(String conversationId, double amount) async {
    await remoteDataSource.sendOffer(conversationId, amount);
  }
  
  @override
  Future<void> respondOffer(String messageId, String action) async {
    await remoteDataSource.respondToOffer(messageId, action);
  }

  @override
  Future<void> archiveChat(String conversationId, bool isArchived) async {
    await remoteDataSource.archiveChat(conversationId, isArchived);
  }

  @override
  Future<void> deleteChat(String conversationId) async {
    await remoteDataSource.deleteChat(conversationId);
  }

  @override
  Future<String?> uploadChatMedia(String conversationId, String filePath) async {
    return await remoteDataSource.uploadMedia(conversationId, filePath);
  }
}