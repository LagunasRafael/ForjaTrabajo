import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import 'package:forja_trabajo/features/auth/presentation/providers/auth_provider.dart';

final serviceRequestRemoteDataSourceProvider = Provider<ServiceRequestRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ServiceRequestRemoteDataSource(apiClient);
});

class ServiceRequestRemoteDataSource {
  final ApiClient _apiClient;
  Dio get _dio => _apiClient.dio;

  ServiceRequestRemoteDataSource(this._apiClient);

  String get _path => '/services';

  Future<Map<String, dynamic>> createRequest(Map<String, dynamic> requestData, String token) async {
    try {
      final response = await _dio.post(
        '$_path/service-requests',
        data: requestData,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data; // Dio ya lo convierte a Map automáticamente
    } on DioException catch (e) {
      debugPrint("🚨 Error al crear postulación: ${e.response?.data}");
      throw Exception('Error al crear postulación: ${e.message}');
    }
  }

  Future<List<Map<String, dynamic>>> getOffers(String serviceId, String token) async {
    try {
      final response = await _dio.get(
        '$_path/$serviceId/offers',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return List<Map<String, dynamic>>.from(response.data);
    } on DioException catch (e) {
      debugPrint("🚨 Error al cargar ofertas: ${e.response?.data}");
      throw Exception('Error al cargar ofertas: ${e.message}');
    }
  }

  Future<Map<String, dynamic>> acceptPostulation(String requestId, String token) async {
    try {
      final response = await _dio.post(
        '$_path/accept-postulation/$requestId',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } on DioException catch (e) {
      debugPrint("🚨 Error al aceptar postulación: ${e.response?.data}");
      throw Exception('Error al aceptar postulación: ${e.message}');
    }
  }

  Future<List<Map<String, dynamic>>> getMyApplications() async {
    try {
      const String ruta = '/services/worker/my-applications';

      // Leer el token directamente de FlutterSecureStorage (misma fuente que el interceptor)
      final token = await _apiClient.storage.read(key: 'jwt_token');
      debugPrint("🔍 Intentando conectar a: ${_dio.options.baseUrl}$ruta");
      debugPrint("🔑 Token disponible: ${token != null ? 'SÍ (${token.length} chars)' : 'NO (null)'}");

      if (token == null || token.isEmpty) {
        throw Exception('No hay sesión activa. Por favor inicia sesión de nuevo.');
      }

      final response = await _dio.get(
        ruta,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      
      return List<Map<String, dynamic>>.from(response.data);
    } on DioException catch (e) {
      debugPrint("🚨 Error Dio en getMyApplications:");
      debugPrint("   Tipo: ${e.type}");
      debugPrint("   Código HTTP: ${e.response?.statusCode}");
      debugPrint("   Mensaje: ${e.message}");
      debugPrint("   Datos: ${e.response?.data}");
      throw Exception('Error al cargar mis postulaciones (${e.response?.statusCode ?? e.type.name})');
    }
  }

  Future<bool> updatePostulation(String requestId, String description, double proposedPrice, String token) async {
    try {
      final response = await _dio.put(
        '$_path/service-requests/$requestId',
        data: {
          "description": description,
          "proposed_price": proposedPrice,
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } on DioException catch (e) {
      debugPrint("🚨 Error al actualizar postulación: ${e.response?.data}");
      throw Exception('Error al actualizar: ${e.message}');
    }
  }
}