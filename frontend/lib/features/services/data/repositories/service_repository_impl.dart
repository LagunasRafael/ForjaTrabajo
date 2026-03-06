import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  Future<void> createCategory(String name, String desc, String token) => categoryDS.createCategory(name, desc, token);

  @override
  Future<void> deleteCategory(String id, String token) => categoryDS.deleteCategory(id, token);

  // --- SERVICIOS ---
  @override
  Future<List<ServiceEntity>> getServices() => serviceDS.getServices();

  @override
  Future<List<ServiceEntity>> getServicesByCategory(String id) => serviceDS.getServicesByCategory(id);

  @override
  Future<List<ServiceEntity>> searchServices(String query) => serviceDS.searchServices(query);

  @override
  Future<ServiceEntity> getServiceById(String id) => serviceDS.getServiceById(id);

  @override
  Future<ServiceEntity> createService(ServiceEntity service, String token, {List<File>? images}) async {
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
      // Llamamos al DataSource que acabamos de crear arriba
      return await serviceDS.cancelService(serviceId, token);
    } catch (e) {
      print("🚨 Error en Repository al cancelar: $e");
      rethrow; // Pasamos el error para que la UI (Riverpod) lo atrape
    }
  }

    // --- SOLICITUDES Y OFERTAS ---
    @override
    Future<ServiceRequestEntity> createRequest(ServiceRequestEntity request, String token) async {
      final result = await requestDS.createRequest(ServiceRequestModel.fromEntity(request).toJson(), token);
      return ServiceRequestModel.fromJson(result);
    }

    @override
    Future<List<ServiceRequestEntity>> getOffers(String serviceId, String token) async {
      final result = await requestDS.getOffers(serviceId, token);
      return result.map((json) => ServiceRequestModel.fromJson(json)).toList();
    }

  @override
  Future<void> acceptPostulation(String requestId, String token) async {
    try {
      final response = await _dio.post(
        '/services/accept-postulation/$requestId',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Error al aceptar postulación: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print("🚨 Error Dio en acceptPostulation: ${e.response?.data}");
      throw Exception('Fallo al conectar con el servidor para aceptar la postulación.');
    }
  }

  @override
  Future<List<ServiceEntity>> getMyApplications(String token) async {
    try {
      final List<dynamic> data = await requestDS.getMyApplications(token);
      
      return data.map<ServiceEntity>((json) {
        final serviceMap = json as Map<String, dynamic>;
        final service = ServiceModel.fromJson(serviceMap).toEntity();
        
        final precioReal = (serviceMap['base_price'] as num?)?.toDouble() ?? 0.0;
        
        return service.copyWith(
          requestId: serviceMap['request_id']?.toString(), 
          basePrice: precioReal, 
        );
      }).toList();

    } catch (e) {
      print("🚨 Error FATAL en getMyApplications: $e");
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
    } on DioException catch (e) {
      print("🚨 Error de red al retirar postulación: ${e.message}");
      return false; 
    } catch (e) {
      print("🚨 Error inesperado al retirar: $e");
      return false;
    }
  }

  // --- TRABAJOS (JOBS) ---
  @override
  Future<JobEntity> completeJob(String jobId, String token) => jobDS.completeJob(jobId, token);

  @override
  Future<JobEntity> cancelJob(String jobId, String token) async {
    return await jobDS.cancelJob(jobId, token);
  }
  
  @override
  Future<bool> completeService(String serviceId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      
      if (token.isEmpty) return false;

      final result = await jobDS.completeJob(serviceId, token);
      return result.id.isNotEmpty;
    } catch (e) {
      print("🚨 Error en Repository.completeService: $e");
      return false;
    }
  }
}

// --- PROVIDER ---
final serviceRepositoryProvider = Provider<ServiceRepository>((ref) {
  return ServiceRepositoryImpl(
    categoryDS: ref.watch(categoryRemoteDataSourceProvider),
    serviceDS: ref.watch(serviceRemoteDataSourceProvider),
    requestDS: ref.watch(serviceRequestRemoteDataSourceProvider),
    jobDS: ref.watch(jobRemoteDataSourceProvider),
    dio: Dio(
      BaseOptions(
        baseUrl: 'http://10.0.2.2:8000', 
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
    ), 
  );
});