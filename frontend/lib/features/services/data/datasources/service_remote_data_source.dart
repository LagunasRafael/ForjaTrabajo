import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../models/service_model.dart';

// 1. PROVIDER: Configurado para inyectar Dio
final serviceRemoteDataSourceProvider = Provider((ref) {
  return ServiceRemoteDataSource(Dio()); 
});

class ServiceRemoteDataSource {
  final Dio _dio;
  final String baseUrl = "http://127.0.0.1:8000/services"; 
  //final String baseUrl = "http://10.0.2.2:8000/services"; 

  ServiceRemoteDataSource(this._dio); 

  // --- MÉTODOS DE CONSULTA (GET) ---

  Future<List<ServiceModel>> getServices() async {
    final response = await http.get(Uri.parse('$baseUrl/')); 
    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((e) => ServiceModel.fromJson(e)).toList();
    } else {
      throw Exception('Error cargando servicios');
    }
  }

  Future<List<ServiceModel>> getServicesByCategory(String categoryId) async {
    final response = await http.get(Uri.parse('$baseUrl/category/$categoryId'));
    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((e) => ServiceModel.fromJson(e)).toList();
    } else {
      throw Exception('Error filtrando por categoría');
    }
  }

  Future<ServiceModel> getServiceById(String id) async {
    final response = await http.get(Uri.parse('$baseUrl/$id'));
    if (response.statusCode == 200) {
      return ServiceModel.fromJson(json.decode(response.body));
    } else {
      throw Exception('Error al obtener el detalle del servicio');
    }
  }

  // --- CREACIÓN CON IMÁGENES (Usa Dio + FormData) ---

  Future<ServiceModel> createService(
    ServiceModel service,
    String token,
    {List<File>? images}
  ) async {
    // Preparamos los datos incluyendo archivos si existen
    final formData = FormData.fromMap({
      'title': service.title,
      'description': service.description,
      'base_price': service.basePrice,
      'category_id': service.categoryId,
      'exact_address': service.exactAddress,
      'latitude': service.latitude,
      'longitude': service.longitude,
      if (images != null && images.isNotEmpty)
        'files': [
          for (var image in images)
            await MultipartFile.fromFile(
              image.path, 
              filename: image.path.split('/').last
            ),
        ],
    });

    try {
      final response = await _dio.post(
        '$baseUrl/', 
        data: formData,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          contentType: 'multipart/form-data',
        ),
      );

      print("📦 RESPUESTA CRUDA DE FASTAPI: ${response.data}");
      return ServiceModel.fromJson(response.data); 
      
    } on DioException catch (e) {
      print("🚨 Error de Dio al crear servicio: ${e.response?.data}");
      throw Exception("Error de red: ${e.message}");
    } catch (e) {
      print("💥 ERROR DE PARSEO: $e");
      throw Exception("Error al leer la respuesta del servidor: $e");
    }
  }

  // --- OTROS MÉTODOS ---

  Future<List<ServiceModel>> searchServices(String searchText) async {
    final url = Uri.parse("$baseUrl/search").replace(
      queryParameters: {'query': searchText} 
    );

    final response = await http.get(url); 
    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((e) => ServiceModel.fromJson(e)).toList();
    } else {
      print("🚨 Error en búsqueda: ${response.body}");
      return []; 
    }
  }

  Future<ServiceModel> updateService(ServiceModel service, String token) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/${service.id}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(service.toJson()),
      );
      
      if (response.statusCode == 200) {
        return ServiceModel.fromJson(json.decode(response.body));
      } else {
        throw Exception("Error al actualizar (${response.statusCode})");
      }
    } catch (e) {
      throw Exception("Error de conexión al actualizar: $e");
    }
  }

  Future<List<ServiceModel>> getMyServices(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/my-requests'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((e) => ServiceModel.fromJson(e)).toList();
    } else {
      throw Exception('Error al cargar mis trabajos: ${response.body}');
    }
  }

  Future<bool> completeService(String serviceId, String token) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/jobs/$serviceId/complete'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}