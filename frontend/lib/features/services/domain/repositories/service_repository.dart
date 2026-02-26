import '../entities/category_entity.dart';
import '../entities/service_entity.dart';
import '../entities/service_request_entity.dart';
import '../entities/job_entity.dart';

abstract class ServiceRepository {
  // Services
  Future<List<ServiceEntity>> getServices();
  Future<List<ServiceEntity>> getServicesByCategory(String categoryId);
  Future<ServiceEntity> createService(ServiceEntity service, String token);
  Future<void> updateService(ServiceEntity service, String token);
  Future<List<ServiceEntity>> getMyServices();
  Future<bool> completeService(String serviceId);
  Future<ServiceEntity> getServiceById(String id);

  // Categories
  Future<List<CategoryEntity>> getCategories();
  Future<List<CategoryEntity>> getTopCategories();
  Future<void> createCategory(String name, String description, String token);// 👈 Agregamos String token
  Future<void> deleteCategory(String id, String token);   // 👈 Agregamos String token

  // Requests
  Future<ServiceRequestEntity> createRequest(ServiceRequestEntity request, String token);
  Future<List<ServiceRequestEntity>> getOffers(String serviceId, String token);
  Future<void> acceptPostulation(String requestId, String token);

  // Jobs
  Future<JobEntity> completeJob(String jobId, String token);
  Future<JobEntity> cancelJob(String jobId, String token);

  // Busqueda
  Future<List<ServiceEntity>> searchServices(String query);
  
}