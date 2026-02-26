import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/service_model.dart';

final serviceRemoteDataSourceProvider = Provider((ref) => ServiceRemoteDataSource());

class ServiceRemoteDataSource {
  // Nota: baseUrl ya incluye "/services" al final
  final String baseUrl = "http://127.0.0.1:8000/services"; 

  Future<List<ServiceModel>> getServices() async {
    final response = await http.get(Uri.parse('$baseUrl/')); 
    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((e) => ServiceModel.fromJson(e)).toList();
    } else {
      throw Exception('Error cargando servicios');
    }
  }

  Future<List<ServiceModel>> getServicesByCategory(String categoryId) async {
    final response = await http.get(Uri.parse('$baseUrl/category/$categoryId'));
    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((e) => ServiceModel.fromJson(e)).toList();
    } else {
      throw Exception('Error filtrando');
    }
  }

  Future<ServiceModel> getServiceById(String id) async {
  final response = await http.get(Uri.parse('$baseUrl/$id'));

  if (response.statusCode == 200) {
    return ServiceModel.fromJson(json.decode(response.body));
  } else {
    throw Exception('Error al obtener el detalle del servicio');
  }
}

  Future<ServiceModel> createService(ServiceModel service, String token) async {
    final response = await http.post(
      Uri.parse('$baseUrl/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(service.toJson()),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return ServiceModel.fromJson(json.decode(response.body));
    } else {
      throw Exception('Error al crear servicio: ${response.body}');
    }
  }

  Future<List<ServiceModel>> searchServices(String searchText) async {
    final url = Uri.parse("$baseUrl/search").replace(
      queryParameters: {'query': searchText} 
    );

    final response = await http.get(url); 

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((e) => ServiceModel.fromJson(e)).toList();
    } else {
      print("🚨 Error en búsqueda (${response.statusCode}): ${response.body}");
      return []; 
    }
  }

  Future<ServiceModel> updateService(ServiceModel service, String token) async {
    try {
      final url = Uri.parse('$baseUrl/${service.id}');
      
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(service.toJson()),
      );
      
      if (response.statusCode == 200) {
        return ServiceModel.fromJson(json.decode(response.body));
      } else {
        throw Exception("Error al actualizar (${response.statusCode}): ${response.body}");
      }
    } catch (e) {
      throw Exception("Error de conexión al actualizar: $e");
    }
  }

  // ✅✅✅ AQUI AGREGAMOS LA NUEVA FUNCIÓN
  Future<List<ServiceModel>> getMyServices(String token) async {
    // La URL final será: http://127.0.0.1:8000/services/my-requests
    final url = Uri.parse('$baseUrl/my-requests'); 

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token', // Necesario para identificar al usuario
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((e) => ServiceModel.fromJson(e)).toList();
    } else {
      throw Exception('Error al cargar mis trabajos: ${response.body}');
    }
  }

  Future<bool> completeService(String serviceId, String token) async {
    try {
      final url = Uri.parse('$baseUrl/jobs/$serviceId/complete');
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}