import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/repositories/service_repository.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/entities/service_entity.dart';
import '../../domain/entities/service_request_entity.dart';
import '../../domain/entities/job_entity.dart';

// Imports de DataSources y Models
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

  ServiceRepositoryImpl({
    required this.categoryDS,
    required this.serviceDS,
    required this.requestDS,
    required this.jobDS,
  });

  @override
  Future<List<CategoryEntity>> getCategories() => categoryDS.getCategories();

  @override
  Future<List<ServiceEntity>> getServices() => serviceDS.getServices();

  @override
  Future<List<ServiceEntity>> getServicesByCategory(String id) => serviceDS.getServicesByCategory(id);

  @override
  Future<ServiceEntity> createService(ServiceEntity service, String token) async {
    // Convertimos Entity a Model para que el DataSource lo pueda procesar
    final model = ServiceModel(
      id: service.id,
      title: service.title,
      description: service.description,
      basePrice: service.basePrice,
      categoryId: service.categoryId,
      clientId: service.clientId,
      status: service.status,
      isActive: service.isActive,
      createdAt: service.createdAt,
    );
    // Usamos serviceDS que está definida arriba en la clase
    return await serviceDS.createService(model, token);
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

// PROVIDER DEL REPOSITORIO
final serviceRepositoryProvider = Provider<ServiceRepository>((ref) {
  return ServiceRepositoryImpl(
    categoryDS: ref.watch(categoryRemoteDataSourceProvider),
    serviceDS: ref.watch(serviceRemoteDataSourceProvider),
    requestDS: ref.watch(serviceRequestRemoteDataSourceProvider),
    jobDS: ref.watch(jobRemoteDataSourceProvider),
  );
});