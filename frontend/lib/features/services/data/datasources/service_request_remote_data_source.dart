import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Importamos el ApiClient y tu AuthProvider para que encuentre el apiClientProvider
import '../../../../core/network/api_client.dart';
import 'package:forja_trabajo/features/auth/presentation/providers/auth_provider.dart';

// 1. PROVIDER: Inyectamos el ApiClient centralizado con Dio
final serviceRequestRemoteDataSourceProvider = Provider<ServiceRequestRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ServiceRequestRemoteDataSource(apiClient.dio);
});

// 2. Definimos la clase que conecta con Internet
class ServiceRequestRemoteDataSource {
  final Dio _dio;

  ServiceRequestRemoteDataSource(this._dio);

  // 🌍 Base URL para este módulo (asumiendo que en Python el router tiene prefix="/services")
  String get _path => '/services';

  // ---------------------------------------------------------------------------
  // CREAR UNA OFERTA (Worker)
  // ---------------------------------------------------------------------------
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

  // ---------------------------------------------------------------------------
  // OBTENER OFERTAS DE UN SERVICIO (Cliente)
  // ---------------------------------------------------------------------------
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

  // ---------------------------------------------------------------------------
  // ACEPTAR UNA OFERTA (Cliente)
  // ---------------------------------------------------------------------------
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

  // ---------------------------------------------------------------------------
  // OBTENER MIS POSTULACIONES (Worker)
  // ---------------------------------------------------------------------------
  Future<List<Map<String, dynamic>>> getMyApplications(String token) async {
    try {
      // 💡 RUTA OPCIÓN 1: Con prefijo
      String rutaAProbar = '/services/worker/my-applications';
      
      // Si te sigue dando 404, comenta la línea de arriba y descomenta esta:
      // String rutaAProbar = '/worker/my-applications';

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

  // ---------------------------------------------------------------------------
  // ACTUALIZAR UNA POSTULACIÓN (Worker)
  // ---------------------------------------------------------------------------
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