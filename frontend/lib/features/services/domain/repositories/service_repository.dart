import 'dart:io';
import '../entities/category_entity.dart';
import '../entities/service_entity.dart';
import '../entities/service_request_entity.dart';
import '../entities/job_entity.dart';
import '../entities/work_evidence_entity.dart';

abstract class ServiceRepository {
  // --- SERVICIOS (SERVICES) ---
  Future<List<ServiceEntity>> getServices({String? categoryId, String? query, double? latitude, double? longitude, double? radiusKm});
  Future<List<ServiceEntity>> getServicesByCategory(String categoryId);
  Future<ServiceEntity> getServiceById(String id);
  Future<List<ServiceEntity>> searchServices(String query);
  Future<ServiceEntity> createService(ServiceEntity service, String token, {List<File>? images});
  Future<ServiceEntity> updateService(ServiceEntity service, String token);
  Future<bool> cancelService(String serviceId, String token);
  Future<bool> hideFromHistory(String serviceId, String token);
  Future<List<ServiceEntity>> getMyServices();
  Future<bool> completeService(String serviceId);

  // --- CATEGORÍAS (CATEGORIES) ---
  Future<List<CategoryEntity>> getCategories();
  Future<List<CategoryEntity>> getTopCategories();
  Future<void> createCategory(String name, String description, String token);
  Future<void> deleteCategory(String id, String token);   

  // --- SOLICITUDES (REQUESTS) ---
  Future<ServiceRequestEntity> createRequest(ServiceRequestEntity request, String token);
  Future<List<ServiceRequestEntity>> getOffers(String serviceId, String token);
  Future<Map<String, dynamic>> acceptPostulation(String requestId, String token);
  Future<List<ServiceEntity>> getMyApplications();
  Future<bool> updatePostulation(String requestId, String description, double proposedPrice, String token);
  Future<bool> deletePostulation(String requestId, String token);

  // --- TRABAJOS (JOBS) ---
  Future<JobEntity> completeJob(String jobId, String token);
  Future<JobEntity> cancelJob(String jobId, String token);

  // --- EVIDENCIAS (WORK EVIDENCES) ---
  Future<List<WorkEvidenceEntity>> getEvidences(String serviceId);
  Future<WorkEvidenceEntity> uploadEvidence(String serviceId, File imageFile, String? description);
  Future<bool> deleteEvidence(String serviceId, String evidenceId);
}