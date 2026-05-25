import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
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

  Future<Map<String, dynamic>> sendOffer(String conversationId, double amount) async {
    try {
      final response = await _apiClient.dio.post(
        '/services/chat/offer',
        data: {
          "conversation_id": conversationId,
          "amount": amount,
        },
      );
      print("✅ Oferta enviada con éxito: \$$amount");
      return response.data;
    } catch (e) {
      print("🚨 ERROR EN DATASOURCE (SEND OFFER): $e");
      rethrow;
    }
  }

  Future<Map<String, dynamic>> respondToOffer(String messageId, String action) async {
    try {
      final response = await _apiClient.dio.post(
        '/services/chat/offer/$messageId/action',
        data: {"action": action}, // "accept" o "reject"
      );
      print("✅ Oferta respondida: $action");
      return response.data;
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
      final ext = filePath.split('.').last.toLowerCase();
      String contentType;
      if (['jpg', 'jpeg', 'png', 'webp'].contains(ext)) {
        contentType = 'image/jpeg';
      } else if (['mp4', 'mov', 'mkv'].contains(ext)) {
        contentType = 'video/mp4';
      } else if (['m4a', 'aac'].contains(ext)) {
        contentType = 'audio/m4a';
      } else if (ext == 'mp3') {
        contentType = 'audio/mpeg';
      } else if (ext == 'ogg') {
        contentType = 'audio/ogg';
      } else if (ext == 'wav') {
        contentType = 'audio/wav';
      } else if (ext == 'opus') {
        contentType = 'audio/opus';
      } else {
        contentType = 'application/octet-stream';
      }

      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          filePath,
          filename: 'media.$ext',
          contentType: MediaType.parse(contentType),
        ),
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

  Future<Map<String, dynamic>> openDispute(String conversationId, String reason) async {
    try {
      final response = await _apiClient.dio.post(
        '/services/chat/$conversationId/dispute',
        data: {"reason": reason},
      );
      print("Disputa abierta exitosamente para la conversación: $conversationId");
      return response.data as Map<String, dynamic>;
    } catch (e) {
      print("ERROR EN DATASOURCE (OPEN DISPUTE): $e");
      rethrow;
    }
  }

  Future<Map<String, dynamic>> sendMessageRest(String conversationId, String content, String messageType) async {
    final response = await _apiClient.dio.post(
      '/services/chat/$conversationId/message',
      data: {
        "content": content,
        "message_type": messageType,
      },
    );
    print("Mensaje enviado por REST: ${response.data['id']}");
    return response.data;
  }

  Future<void> markAsRead(String conversationId) async {
    try {
      await _apiClient.dio.post('/services/chat/$conversationId/read');
      print("✅ Chat marcado como leído: $conversationId");
    } catch (e) {
      // No lanzamos error para no interrumpir el flujo si falla el mark-as-read
      print("⚠️ Error silencioso en markAsRead: $e");
    }
  }
}