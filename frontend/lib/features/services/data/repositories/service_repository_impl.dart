import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Imports de Dominio
import '../../domain/repositories/service_repository.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/entities/service_entity.dart';
import '../../domain/entities/service_request_entity.dart';
import '../../domain/entities/job_entity.dart';

// Imports de Datos
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
  final Dio _dio; // Nuestra variable privada sigue igual

  // 👇 CORRECCIÓN AQUÍ: Recibimos 'dio' y lo asignamos a '_dio'
  ServiceRepositoryImpl({
    required this.categoryDS,
    required this.serviceDS,
    required this.requestDS,
    required this.jobDS,
    required Dio dio, // El parámetro con nombre no lleva guion bajo
  }) : _dio = dio; // Se asigna aquí antes de entrar al cuerpo del constructor

  @override
  Future<List<CategoryEntity>> getCategories() => categoryDS.getCategories();

  @override
  Future<List<CategoryEntity>> getTopCategories() => categoryDS.getTopCategories();

  @override
  Future<void> createCategory(String name, String description, String token) async {
    return await categoryDS.createCategory(name, description, token);
  }

  @override
  Future<void> deleteCategory(String id, String token) async {
    return await categoryDS.deleteCategory(id, token);
  }

  @override
  Future<List<ServiceEntity>> getServices() => serviceDS.getServices();

  @override
  Future<List<ServiceEntity>> getServicesByCategory(String id) => 
      serviceDS.getServicesByCategory(id);

  @override
  Future<List<ServiceEntity>> searchServices(String query) => 
      serviceDS.searchServices(query);

  @override
  Future<ServiceEntity> createService(
    ServiceEntity service, 
    String token, 
    {List<File>? images}
  ) async {
    final model = ServiceModel(
      id: service.id,
      title: service.title,
      description: service.description,
      basePrice: service.basePrice,
      categoryId: service.categoryId,
      clientId: service.clientId,
      latitude: service.latitude, 
      longitude: service.longitude,
      exactAddress: service.exactAddress,
      status: service.status,
      isActive: service.isActive,
      createdAt: service.createdAt,
    );
    
    return await serviceDS.createService(model, token, images: images);
  }

  @override
  Future<ServiceRequestEntity> createRequest(ServiceRequestEntity request, String token) {
    final model = ServiceRequestModel(
      id: request.id,
      serviceId: request.serviceId,
      workerId: request.workerId,
      description: request.description,
      status: request.status,
      createdAt: request.createdAt,
    );
    return requestDS.createRequest(model, token);
  }

  @override
  Future<List<ServiceRequestEntity>> getOffers(String serviceId, String token) => 
      requestDS.getOffers(serviceId, token);

  @override
  Future<JobEntity> acceptPostulation(String requestId, String token) => 
      requestDS.acceptPostulation(requestId, token);

  @override
  Future<JobEntity> completeJob(String jobId, String token) => 
      jobDS.completeJob(jobId, token);

  @override
  Future<JobEntity> cancelJob(String jobId, String token) => 
      jobDS.cancelJob(jobId, token);
}

// --- PROVIDER DEL REPOSITORIO ---
final serviceRepositoryProvider = Provider<ServiceRepository>((ref) {
  // Asegúrate de usar tu dioProvider aquí si ya lo tienes
  // final dio = ref.watch(dioProvider); 
  
  return ServiceRepositoryImpl(
    categoryDS: ref.watch(categoryRemoteDataSourceProvider),
    serviceDS: ref.watch(serviceRemoteDataSourceProvider),
    requestDS: ref.watch(serviceRequestRemoteDataSourceProvider),
    jobDS: ref.watch(jobRemoteDataSourceProvider),
    dio: Dio(), // 👈 Pasamos 'dio' sin guion bajo
  );
});