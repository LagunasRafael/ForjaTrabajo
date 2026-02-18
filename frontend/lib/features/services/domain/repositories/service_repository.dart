import '../entities/category_entity.dart';
import '../entities/service_entity.dart';
import '../entities/service_request_entity.dart';
import '../entities/job_entity.dart';

abstract class ServiceRepository {
  // Services
  Future<List<ServiceEntity>> getServices();
  Future<List<ServiceEntity>> getServicesByCategory(String categoryId);
  Future<ServiceEntity> createService(ServiceEntity service, String token);

  // Categories
  Future<List<CategoryEntity>> getCategories();

  // Requests
  Future<ServiceRequestEntity> createRequest(ServiceRequestEntity request, String token);
  Future<List<ServiceRequestEntity>> getOffers(String serviceId, String token);
  Future<JobEntity> acceptPostulation(String requestId, String token);

  // Jobs
  Future<JobEntity> completeJob(String jobId, String token);
  Future<JobEntity> cancelJob(String jobId, String token);
  
}