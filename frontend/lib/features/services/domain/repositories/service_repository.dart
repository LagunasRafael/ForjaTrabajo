import '../entities/category_entity.dart';
import '../entities/service_entity.dart';
import '../entities/service_request_entity.dart';
import '../entities/job_entity.dart';
import 'dart:io';

abstract class ServiceRepository {
  // Services
  Future<List<ServiceEntity>> getServices();
  Future<List<ServiceEntity>> getServicesByCategory(String categoryId);
  
  // 👇 AQUÍ ESTÁ LA CORRECCIÓN: Agregamos {List<File>? images}
  Future<ServiceEntity> createService(ServiceEntity service, String token, {List<File>? images});

  // Categories
  Future<List<CategoryEntity>> getCategories();
  Future<List<CategoryEntity>> getTopCategories();
  Future<void> createCategory(String name, String description, String token);
  Future<void> deleteCategory(String id, String token);   

  // Requests
  Future<ServiceRequestEntity> createRequest(ServiceRequestEntity request, String token);
  Future<List<ServiceRequestEntity>> getOffers(String serviceId, String token);
  Future<JobEntity> acceptPostulation(String requestId, String token);

  // Jobs
  Future<JobEntity> completeJob(String jobId, String token);
  Future<JobEntity> cancelJob(String jobId, String token);

  // Busqueda
  Future<List<ServiceEntity>> searchServices(String query);
}