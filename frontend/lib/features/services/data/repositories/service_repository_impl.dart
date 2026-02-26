import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart'; // ✅ NECESARIO PARA EL TOKEN
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
import '../models/job_model.dart';

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

  // --- CATEGORÍAS ---
  @override
  Future<List<CategoryEntity>> getCategories() => categoryDS.getCategories();

  @override
  Future<void> createCategory(String name, String description, String token) async {
    return await categoryDS.createCategory(name, description, token);
  }

  @override
  Future<void> deleteCategory(String id, String token) async {
    return await categoryDS.deleteCategory(id, token);
  }

  // --- SERVICIOS ---
  @override
  Future<List<ServiceEntity>> getServices() => serviceDS.getServices();

  @override
  Future<List<ServiceEntity>> getServicesByCategory(String id) => 
      serviceDS.getServicesByCategory(id);

  @override
  Future<ServiceEntity> createService(ServiceEntity service, String token) async {
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
      latitude: service.latitude,      // Asegúrate de pasar estos si los tienes
      longitude: service.longitude,
      exactAddress: service.exactAddress,
      imageUrls: service.imageUrls,
    );
    return await serviceDS.createService(model, token);
  }

  // ✅ CORRECCIÓN DE getMyServices
  @override
  Future<List<ServiceEntity>> getMyServices() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      // Usamos 'serviceDS' que es la variable definida arriba
      final models = await serviceDS.getMyServices(token ?? ''); 
      
      return models.map((m) => m.toEntity()).toList();
    } catch (e) {
      throw Exception("Fallo en repositorio al cargar mis servicios: $e");
    }
  }

  // --- SOLICITUDES Y OFERTAS ---
  @override
  Future<ServiceRequestEntity> createRequest(ServiceRequestEntity request, String token) async {
    final model = ServiceRequestModel.fromEntity(request).toJson();
    final result = await requestDS.createRequest(model, token);
    return ServiceRequestModel.fromJson(result);
  }

  @override
  Future<List<ServiceRequestEntity>> getOffers(String serviceId, String token) async {
    final List<Map<String, dynamic>> result = await requestDS.getOffers(serviceId, token);
    return result.map((json) => ServiceRequestModel.fromJson(json)).toList();
  }

Future<void> acceptPostulation(String requestId, String token) async {
  final url = Uri.parse("http://127.0.0.1:8000/services/accept-postulation/$requestId");

  final response = await http.post(
    url,
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
  );

  if (response.statusCode == 200 || response.statusCode == 201) {
    return; 
  } else {
    throw Exception('Error al aceptar postulacion: ${response.statusCode}');
  }
}

  // --- TRABAJOS (JOBS) ---
  @override
  Future<JobEntity> completeJob(String jobId, String token) => 
      jobDS.completeJob(jobId, token);

  @override
  Future<JobEntity> cancelJob(String jobId, String token) => 
      jobDS.cancelJob(jobId, token);

  // --- EXTRAS ---
  @override
  Future<List<CategoryEntity>> getTopCategories() => categoryDS.getTopCategories();

  @override
  Future<List<ServiceEntity>> searchServices(String query) => 
      serviceDS.searchServices(query);

  @override
  Future<ServiceEntity> updateService(ServiceEntity service, String token) async {
    final model = ServiceModel.fromEntity(service); // Asegúrate de tener este método en tu modelo
    final updatedModel = await serviceDS.updateService(model, token);
    return updatedModel.toEntity();
  }

@override
  Future<bool> completeService(String serviceId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      // Llamamos a la función que pusimos en el archivo de arriba
      return await serviceDS.completeService(serviceId, token);
    } catch (e) {
      return false;
    }
  }
  @override
  Future<ServiceEntity> getServiceById(String id) async {
  // Aquí llamamos al Data Source y devolvemos la entidad
  return await serviceDS.getServiceById(id);
}
}

// PROVIDER DEL REPOSITORIO
final serviceRepositoryProvider = Provider<ServiceRepository>((ref) {
  return ServiceRepositoryImpl(
    categoryDS: ref.watch(categoryRemoteDataSourceProvider),
    serviceDS: ref.watch(serviceRemoteDataSourceProvider),
    requestDS: ref.watch(serviceRequestRemoteDataSourceProvider),
    jobDS: ref.watch(jobRemoteDataSourceProvider), // Asegúrate de tener este provider creado
  );
});