import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

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
    final models = await serviceDS.getMyServices(token); 
    return models.map((m) => m.toEntity()).toList();
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
   // final url = Uri.parse("http://127.0.0.1:8000/services/accept-postulation/$requestId");
    final url = Uri.parse("http://10.0.2.2:8000/services/accept-postulation/$requestId");

    final response = await http.post(url, headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    });
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Error al aceptar postulacion: ${response.statusCode}');
    }
  }

@override
  Future<List<ServiceEntity>> getMyApplications(String token) async {
    // 1. Obtenemos la lista de JSONs desde el DataSource
    final List<Map<String, dynamic>> data = await requestDS.getMyApplications(token);
    
    // 2. Usamos tu ServiceModel para mapear el JSON y luego lo convertimos a Entity
    return data.map((json) {
      final model = ServiceModel.fromJson(json);
      return model.toEntity();
    }).toList();
  }

  @override
  Future<bool> updatePostulation(String requestId, String description, double proposedPrice, String token) {
    return requestDS.updatePostulation(requestId, description, proposedPrice, token);
  }
  // --- TRABAJOS (JOBS) ---
  @override
  Future<JobEntity> completeJob(String jobId, String token) => jobDS.completeJob(jobId, token);

  @override
  Future<JobEntity> cancelJob(String jobId, String token) => jobDS.cancelJob(jobId, token);

  @override
  Future<bool> completeService(String serviceId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      
      if (token.isEmpty) return false;

      // 🚀 CAMBIO CLAVE: Usamos jobDS en lugar de serviceDS
      // Porque lo que estamos terminando es un contrato (JOB)
      // Y nos aseguramos de que el resultado sea un bool para tu SnackBar
      final result = await jobDS.completeJob(serviceId, token);
      
      // Si el objeto Job regresa con ID, significa que fue un éxito
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
    dio: Dio(), 
  );
});
