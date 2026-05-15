import 'package:dio/dio.dart';
import 'package:forja_trabajo/core/network/api_client.dart';
// Asegúrate de importar tu modelo si lo necesitas
// import '../models/message_model.dart'; 

class ChatRemoteDataSource {
  final ApiClient _apiClient = ApiClient();

  // 1. OBTENER O CREAR SALA
  Future<String> startOrGetChat(String requestId) async {
    try {
      final response = await _apiClient.dio.post('/services/chat/start/$requestId');
      
      // 🕵️‍♂️ AQUÍ ESTÁ EL DETECTIVE:
      print("🚨 RESPUESTA DE PYTHON (NUEVA SALA): ${response.data}");

      // Intentamos sacar el ID. Puede que Python lo llame 'id' o 'conversation_id'
      final chatId = response.data['id'] ?? response.data['conversation_id'];
      
      if (chatId == null) {
        throw Exception("Python no devolvió ningún ID válido en el JSON");
      }

      return chatId.toString();
    } catch (e) {
      print("🚨 ERROR EN DATASOURCE (START CHAT): $e");
      rethrow;
    }
  }

  // 👇 2. OBTENER HISTORIAL (AQUÍ AGREGAMOS SKIP Y LIMIT)
  Future<List<dynamic>> getHistory(String conversationId, {int skip = 0, int limit = 15}) async {
    try {
      // Usamos queryParameters para que Dio arme la URL: /history?skip=0&limit=20
      final response = await _apiClient.dio.get(
        '/services/chat/$conversationId/history',
        queryParameters: {
          'skip': skip,
          'limit': limit,
        },
      );
      print("🚨 HISTORIAL RECIBIDO: ${response.data}");
      return response.data; 
    } catch (e) {
      print("🚨 ERROR EN DATASOURCE (HISTORY): $e");
      return [];
    }
  }

  Future<List<dynamic>> getUserChats() async {
    try {
      final response = await _apiClient.dio.get('/services/chat/my-chats'); 
      return response.data;
    } catch (e) {
      print("🚨 Error obteniendo lista de chats: $e");
      return [];
    }
  }

  Future<void> sendOffer(String conversationId, double amount) async {
    try {
      await _apiClient.dio.post(
        '/services/chat/offer',
        data: {
          "conversation_id": conversationId,
          "amount": amount,
        },
      );
      print("✅ Oferta enviada con éxito: \$$amount");
    } catch (e) {
      print("🚨 ERROR EN DATASOURCE (SEND OFFER): $e");
      rethrow;
    }
  }

  Future<void> respondToOffer(String messageId, String action) async {
    try {
      await _apiClient.dio.post(
        '/services/chat/offer/$messageId/action',
        data: {"action": action}, // "accept" o "reject"
      );
      print("✅ Oferta respondida: $action");
    } catch (e) {
      print("🚨 ERROR EN DATASOURCE (RESPOND OFFER): $e");
      rethrow;
    }
  }

  Future<void> archiveChat(String conversationId, bool isArchived) async {
    try {
      await _apiClient.dio.post(
        '/services/chat/$conversationId/archive',
        data: {"is_archived": isArchived},
      );
      print("✅ Chat ${isArchived ? 'archivado' : 'desarchivado'}");
    } catch (e) {
      print("🚨 ERROR EN DATASOURCE (ARCHIVE CHAT): $e");
      rethrow;
    }
  }

  Future<void> deleteChat(String conversationId) async {
    try {
      await _apiClient.dio.delete('/services/chat/$conversationId');
      print("✅ Chat eliminado correctamente");
    } catch (e) {
      print("🚨 ERROR EN DATASOURCE (DELETE CHAT): $e");
      rethrow;
    }
  }

  Future<String?> uploadMedia(String conversationId, String filePath) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath),
      });
      final response = await _apiClient.dio.post(
        '/services/chat/$conversationId/upload',
        data: formData,
      );
      print("✅ Media subida con éxito: ${response.data['url']}");
      return response.data['url'] as String;
    } catch (e) {
      print("🚨 ERROR EN DATASOURCE (UPLOAD MEDIA): $e");
      return null;
    }
  }

  Future<void> openDispute(String conversationId, String reason) async {
    try {
      await _apiClient.dio.post(
        '/services/chat/$conversationId/dispute',
        data: {"reason": reason},
      );
      print("✅ Disputa abierta exitosamente para la conversación: $conversationId");
    } catch (e) {
      print("🚨 ERROR EN DATASOURCE (OPEN DISPUTE): $e");
      rethrow;
    }
  }
}