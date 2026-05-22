import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/service_model.dart';
import '../models/work_evidence_model.dart';
import '../../../../core/network/api_client.dart';
import 'package:forja_trabajo/features/auth/presentation/providers/auth_provider.dart';

// 1. PROVIDER: Inyectamos el ApiClient centralizado
final serviceRemoteDataSourceProvider = Provider((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ServiceRemoteDataSource(apiClient.dio);
});

class ServiceRemoteDataSource {
  final Dio _dio;

  ServiceRemoteDataSource(this._dio);

  // 🌍 Base URL para este módulo
  String get _path => '/services';

  // --- MÉTODOS DE CONSULTA (GET) ---

  Future<List<ServiceModel>> getServices({String? categoryId, String? query}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (categoryId != null && categoryId.isNotEmpty) {
        queryParams['category_id'] = categoryId;
      }
      if (query != null && query.trim().isNotEmpty) {
        queryParams['query'] = query.trim();
      }
      final response = await _dio.get(
        '$_path/',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );
      return (response.data as List).map((e) => ServiceModel.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Error al cargar servicios: $e');
    }
  }

  Future<List<ServiceModel>> getServicesByCategory(String categoryId) async {
    try {
      final response = await _dio.get('$_path/category/$categoryId');
      return (response.data as List).map((e) => ServiceModel.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Error al filtrar por categoría: $e');
    }
  }

  Future<ServiceModel> getServiceById(String id) async {
    try {
      final response = await _dio.get('$_path/$id');
      return ServiceModel.fromJson(response.data);
    } catch (e) {
      throw Exception('Error al obtener detalle del servicio: $e');
    }
  }

  Future<List<ServiceModel>> searchServices(String query) async {
    try {
      final response = await _dio.get('$_path/search', queryParameters: {'query': query});
      return (response.data as List).map((e) => ServiceModel.fromJson(e)).toList();
    } catch (e) {
      debugPrint("🚨 Error en búsqueda: $e");
      return [];
    }
  }

  // --- OPERACIONES DE USUARIO (LOGUEADO) ---

  Future<List<ServiceModel>> getMyServices(String token) async {
    try {
      final response = await _dio.get(
        '$_path/my-requests',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      debugPrint("🔍 Client services JSON: ${response.data}");
      return (response.data as List).map((e) => ServiceModel.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Error al cargar tus servicios: $e');
    }
  }

  // --- CREACIÓN CON IMÁGENES (Usa FormData) ---

  Future<ServiceModel> createService(ServiceModel service, String token, {List<File>? images}) async {
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
            await MultipartFile.fromFile(image.path, filename: image.path.split('/').last),
        ],
    });

    try {
      final response = await _dio.post(
        '$_path/',
        data: formData,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          contentType: 'multipart/form-data',
        ),
      );
      return ServiceModel.fromJson(response.data);
    } on DioException catch (e) {
      debugPrint("🚨 Error al crear servicio: ${e.response?.data}");
      throw Exception("Fallo en el servidor: ${e.message}");
    }
  }

  Future<ServiceModel> updateService(ServiceModel service, String token) async {
    try {
      final response = await _dio.put(
        '$_path/${service.id}',
        data: service.toJson(),
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return ServiceModel.fromJson(response.data);
    } catch (e) {
      throw Exception("Error al actualizar servicio: $e");
    }
  }

  // --- GESTIÓN DE ESTADOS (CANCELAR / COMPLETAR) ---

  Future<bool> cancelService(String serviceId, String token) async {
    try {
      final response = await _dio.put(
        '$_path/$serviceId/cancel',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("🚨 Error al cancelar servicio: $e");
      return false;
    }
  }

  Future<bool> completeService(String serviceId, String token) async {
    try {
      final response = await _dio.put(
        '$_path/jobs/$serviceId/complete',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("🚨 Error al completar servicio: $e");
      return false;
    }
  }

  Future<List<WorkEvidenceModel>> getEvidences(String serviceId, String token) async {
    try {
      final response = await _dio.get(
        '$_path/$serviceId/evidences',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return (response.data as List).map((e) => WorkEvidenceModel.fromJson(e)).toList();
    } catch (e) {
      debugPrint("🚨 Error al cargar evidencias: $e");
      return [];
    }
  }

  Future<bool> deleteEvidence(String serviceId, String evidenceId, String token) async {
    try {
      final response = await _dio.delete(
        '$_path/$serviceId/evidences/$evidenceId',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("🚨 Error al eliminar evidencia: $e");
      return false;
    }
  }

  Future<WorkEvidenceModel> uploadEvidence(String serviceId, File imageFile, String? description, String token) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(imageFile.path, filename: imageFile.path.split('/').last),
      if (description != null && description.isNotEmpty) 'description': description,
    });

    try {
      final response = await _dio.post(
        '$_path/$serviceId/evidences',
        data: formData,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          contentType: 'multipart/form-data',
        ),
      );
      return WorkEvidenceModel.fromJson(response.data);
    } on DioException catch (e) {
      debugPrint("🚨 Error al subir evidencia: ${e.response?.data}");
      throw Exception("Fallo al subir evidencia: ${e.response?.data?['detail'] ?? e.message}");
    }
  }
}