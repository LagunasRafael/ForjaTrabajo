import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../models/service_model.dart';

// 👇 AQUÍ ESTÁ EL PRIMER FIX: Declaramos el Provider correctamente para pasar el Dio
final serviceRemoteDataSourceProvider = Provider((ref) {
  // Aquí usamos un Dio genérico. Lo ideal es usar un 'dioProvider' si tienes uno configurado.
  return ServiceRemoteDataSource(Dio()); 
});

class ServiceRemoteDataSource {
  final Dio _dio;
  // 👇 SEGUNDO FIX: Constructor correcto
  ServiceRemoteDataSource(this._dio); 
  
  // Ojo: Si usas emulador de Android, 127.0.0.1 a veces falla, mejor usa 10.0.2.2.
  // Pero lo dejaré como lo tienes.
  final String baseUrl = "http://127.0.0.1:8000/services"; 

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
      throw Exception('Error filtrando');
    }
  }

  // 👇 TERCER FIX: Un solo método limpio para crear el servicio
  Future<ServiceModel> createService(
    ServiceModel service,
    String token,
    {List<File>? images}
  ) async {
    final formData = FormData.fromMap({
      'title': service.title,
      'description': service.description,
      'base_price': service.basePrice,
      'category_id': service.categoryId,
      'exact_address': service.exactAddress,
      'latitude': service.latitude,
      'longitude': service.longitude,
      // Solo agregamos archivos si el usuario seleccionó fotos
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
        '$baseUrl/', // <-- Si FastAPI se pone estricto, intenta con '$baseUrl/'
        data: formData,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          contentType: 'multipart/form-data',
        ),
      );

      print("📦 RESPUESTA CRUDA DE FASTAPI: ${response.data}");

      // Convertimos la respuesta exitosa en el modelo
      return ServiceModel.fromJson(response.data); 
      
    } on DioException catch (e) {
      print("🚨 Error de Dio al crear servicio: ${e.response?.data}");
      throw Exception("Error de red: ${e.message}");
    } catch (e, stacktrace) {
      // 👇 3. AQUÍ ATRAPAMOS EL ERROR DE PARSEO SI LA APP INTENTA TRONAR
      print("💥 ERROR FATAL DE PARSEO EN FLUTTER: $e");
      print("🔍 STACKTRACE: $stacktrace");
      throw Exception("Error al leer la respuesta del servidor: $e");
    }
  }

  Future<List<ServiceModel>> searchServices(String searchText) async {
    final url = Uri.parse("$baseUrl/search").replace(
      queryParameters: {'query': searchText} 
    );

    final response = await http.get(url); 

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((e) => ServiceModel.fromJson(e)).toList();
    } else {
      print("🚨 Error en búsqueda (${response.statusCode}): ${response.body}");
      return []; 
    }
  }
}