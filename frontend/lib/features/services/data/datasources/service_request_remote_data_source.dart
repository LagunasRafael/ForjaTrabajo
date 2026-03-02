import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 1. Definimos la clase que conecta con Internet
class ServiceRequestRemoteDataSource {
  // Asegúrate de que este puerto sea el correcto (8000 si usas uvicorn por defecto)
  //final String baseUrl = "http://127.0.0.1:8000/services"; 
  final String baseUrl = "http://10.0.2.2:8000/services";

  // ---------------------------------------------------------------------------
  // CREAR UNA OFERTA (Worker)
  // ---------------------------------------------------------------------------
  Future<Map<String, dynamic>> createRequest(Map<String, dynamic> requestData, String token) async {
    final url = Uri.parse('$baseUrl/service-requests');
    
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json; charset=UTF-8', // Importante para enviar tildes bien
        'Authorization': 'Bearer $token',
      },
      body: json.encode(requestData),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      // ✅ Usamos utf8.decode para leer la respuesta completa sin errores de caracteres
      return json.decode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception('Error al crear postulación (${response.statusCode}): ${utf8.decode(response.bodyBytes)}');
    }
  }

  // ---------------------------------------------------------------------------
  // OBTENER OFERTAS DE UN SERVICIO (Cliente)
  // ---------------------------------------------------------------------------
  Future<List<Map<String, dynamic>>> getOffers(String serviceId, String token) async {
    final url = Uri.parse('$baseUrl/$serviceId/offers');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      // ✅ 1. Decodificamos los bytes para asegurar acentos y caracteres especiales
      String body = utf8.decode(response.bodyBytes);
      
      // ✅ 2. Convertimos a Lista dinámica
      final List<dynamic> decodedList = json.decode(body);
      
      // ✅ 3. Creamos una lista TIPIFICADA segura. 
      // Esto asegura que cada elemento se trate como un Mapa real y no se pierda nada.
      return List<Map<String, dynamic>>.from(decodedList);
    } else {
      throw Exception('Error al cargar ofertas (${response.statusCode}): ${utf8.decode(response.bodyBytes)}');
    }
  }

  // ---------------------------------------------------------------------------
  // ACEPTAR UNA OFERTA (Cliente)
  // ---------------------------------------------------------------------------
  Future<Map<String, dynamic>> acceptPostulation(String requestId, String token) async {
    final url = Uri.parse('$baseUrl/accept-postulation/$requestId');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      // ✅ Decodificación segura
      return json.decode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception('Error al aceptar postulación (${response.statusCode}): ${utf8.decode(response.bodyBytes)}');
    }
  }
}

// 2. Definimos el Provider para que el Repositorio lo encuentre
final serviceRequestRemoteDataSourceProvider = Provider<ServiceRequestRemoteDataSource>((ref) {
  return ServiceRequestRemoteDataSource();
});