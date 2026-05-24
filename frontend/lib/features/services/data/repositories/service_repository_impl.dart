import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/repositories/service_repository.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/entities/service_entity.dart';
import '../../domain/entities/service_request_entity.dart';
import '../../domain/entities/job_entity.dart';
import '../datasources/category_remote_data_source.dart';
import '../datasources/service_remote_data_source.dart';
import '../datasources/service_request_remote_data_source.dart';
import '../datasources/job_remote_data_source.dart';
import '../models/service_model.dart';
import '../models/service_request_model.dart';
import '../models/work_evidence_model.dart';
import 'package:forja_trabajo/features/auth/presentation/providers/auth_provider.dart';
import 'package:forja_trabajo/features/services/domain/entities/work_evidence_entity.dart';

class ServiceRepositoryImpl implements ServiceRepository {
  final CategoryRemoteDataSource categoryDS;
  final ServiceRemoteDataSource serviceDS;
  final ServiceRequestRemoteDataSource requestDS;
  final JobRemoteDataSource jobDS;
  final Dio _dio;

  ServiceRepositoryImpl({
    required this.categoryDS,
    required this.serviceDS,
    required this.requestDS,
    required this.jobDS,
    required Dio dio,
  }) : _dio = dio;

  // --- CATEGORÍAS ---
  @override
  Future<List<CategoryEntity>> getCategories() => categoryDS.getCategories();

  @override
  Future<List<CategoryEntity>> getTopCategories() => categoryDS.getTopCategories();

  @override
  Future<void> createCategory(String name, String desc, String token) =>
      categoryDS.createCategory(name, desc, token);

  @override
  Future<void> deleteCategory(String id, String token) =>
      categoryDS.deleteCategory(id, token);

  // --- SERVICIOS ---
  @override
  Future<List<ServiceEntity>> getServices({String? categoryId, String? query}) =>
      serviceDS.getServices(categoryId: categoryId, query: query);

  @override
  Future<List<ServiceEntity>> getServicesByCategory(String id) =>
      serviceDS.getServicesByCategory(id);

  @override
  Future<List<ServiceEntity>> searchServices(String query) =>
      serviceDS.searchServices(query);

  @override
  Future<ServiceEntity> getServiceById(String id) => serviceDS.getServiceById(id);

  @override
  Future<ServiceEntity> createService(ServiceEntity service, String token,
      {List<File>? images}) async {
    final model = ServiceModel.fromEntity(service);
    return await serviceDS.createService(model, token, images: images);
  }

  @override
  Future<ServiceEntity> updateService(ServiceEntity service, String token) async {
    final model = ServiceModel.fromEntity(service);
    final updated = await serviceDS.updateService(model, token);
    return updated.toEntity();
  }

  @override
  Future<List<ServiceEntity>> getMyServices() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    if (token.isEmpty) return [];

    final models = await serviceDS.getMyServices(token);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<bool> cancelService(String serviceId, String token) async {
    try {
      return await serviceDS.cancelService(serviceId, token);
    } catch (e) {
      debugPrint("🚨 Error en Repository al cancelar: $e");
      rethrow;
    }
  }

  @override
  Future<bool> hideFromHistory(String serviceId, String token) async {
    try {
      return await serviceDS.hideFromHistory(serviceId, token);
    } catch (e) {
      debugPrint("🚨 Error en Repository al ocultar del historial: $e");
      rethrow;
    }
  }

  // --- SOLICITUDES Y OFERTAS ---
  @override
  Future<ServiceRequestEntity> createRequest(ServiceRequestEntity request, String token) async {
    final result = await requestDS.createRequest(
        ServiceRequestModel.fromEntity(request).toJson(), token);
    return ServiceRequestModel.fromJson(result);
  }

  @override
  Future<List<ServiceRequestEntity>> getOffers(String serviceId, String token) async {
    final result = await requestDS.getOffers(serviceId, token);
    return result.map((json) => ServiceRequestModel.fromJson(json)).toList();
  }

  @override
  Future<Map<String, dynamic>> acceptPostulation(String requestId, String token) async {
    try {
      final response = await _dio.post(
        '/services/accept-postulation/$requestId',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Error al aceptar postulación');
      }
      return response.data;
    } on DioException catch (e) {
      debugPrint("🚨 Error Dio en acceptPostulation: ${e.response?.data}");
      throw Exception('Fallo al aceptar la postulación en el servidor.');
    }
  }

  @override
  Future<List<ServiceEntity>> getMyApplications() async {
    try {
      final List<dynamic> data = await requestDS.getMyApplications();
      return data.map<ServiceEntity>((json) {
        final serviceMap = json as Map<String, dynamic>;
        debugPrint("🔍 Worker app JSON: $serviceMap");
        final service = ServiceModel.fromJson(serviceMap).toEntity();
        final precioReal = (serviceMap['base_price'] as num?)?.toDouble() ?? 0.0;
        
        return service.copyWith(
          requestId: serviceMap['request_id']?.toString(),
          basePrice: precioReal,
          alreadyReviewed: serviceMap['already_reviewed'] ?? false,
        );
      }).toList();
    } catch (e) {
      debugPrint("🚨 Error en getMyApplications: $e");
      rethrow;
    }
  }

  @override
  Future<bool> updatePostulation(String requestId, String description, double proposedPrice, String token) {
    return requestDS.updatePostulation(requestId, description, proposedPrice, token);
  }

  @override
  Future<bool> deletePostulation(String requestId, String token) async {
    try {
      await _dio.delete(
        '/services/service-requests/$requestId',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return true;
    } catch (e) {
      debugPrint("🚨 Error al retirar postulación: $e");
      return false;
    }
  }

  // --- TRABAJOS (JOBS) ---
  @override
  Future<JobEntity> completeJob(String jobId, String token) =>
      jobDS.completeJob(jobId, token);

  @override
  Future<JobEntity> cancelJob(String jobId, String token) =>
      jobDS.cancelJob(jobId, token);

  @override
  Future<bool> completeService(String serviceId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      if (token.isEmpty) return false;

      final result = await jobDS.completeJob(serviceId, token);
      return result.id.isNotEmpty;
    } catch (e) {
      debugPrint("🚨 Error en completeService: $e");
      return false;
    }
  }

  // --- EVIDENCIAS ---
  @override
  Future<bool> deleteEvidence(String serviceId, String evidenceId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    if (token.isEmpty) return false;

    return serviceDS.deleteEvidence(serviceId, evidenceId, token);
  }

  @override
  Future<List<WorkEvidenceEntity>> getEvidences(String serviceId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    if (token.isEmpty) return [];

    final models = await serviceDS.getEvidences(serviceId, token);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<WorkEvidenceEntity> uploadEvidence(String serviceId, File imageFile, String? description) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    if (token.isEmpty) throw Exception('No hay sesión activa');

    final model = await serviceDS.uploadEvidence(serviceId, imageFile, description, token);
    return model.toEntity();
  }
}

// --- PROVIDER ---
final serviceRepositoryProvider = Provider<ServiceRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider); 
  
  return ServiceRepositoryImpl(
    categoryDS: ref.watch(categoryRemoteDataSourceProvider),
    serviceDS: ref.watch(serviceRemoteDataSourceProvider),
    requestDS: ref.watch(serviceRequestRemoteDataSourceProvider),
    jobDS: ref.watch(jobRemoteDataSourceProvider),
    dio: apiClient.dio,
  );
});