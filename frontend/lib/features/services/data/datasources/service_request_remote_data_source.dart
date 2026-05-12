import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import 'package:forja_trabajo/features/auth/presentation/providers/auth_provider.dart';

final serviceRequestRemoteDataSourceProvider = Provider<ServiceRequestRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ServiceRequestRemoteDataSource(apiClient.dio);
});

class ServiceRequestRemoteDataSource {
  final Dio _dio;

  ServiceRequestRemoteDataSource(this._dio);

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

  Future<List<Map<String, dynamic>>> getMyApplications(String token) async {
    try {
      // 💡 RUTA OPCIÓN 1: Con prefijo
      String rutaAProbar = '/services/worker/my-applications';

      debugPrint("🔍 Intentando conectar a: ${_dio.options.baseUrl}$rutaAProbar");

      final response = await _dio.get(
        rutaAProbar,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      
      return List<Map<String, dynamic>>.from(response.data);
    } on DioException catch (e) {
      debugPrint("🚨 Error Dio en getMyApplications: Código ${e.response?.statusCode}");
      debugPrint("🚨 Detalles del error: ${e.response?.data}");
      throw Exception('Error al cargar mis postulaciones (${e.response?.statusCode})');
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