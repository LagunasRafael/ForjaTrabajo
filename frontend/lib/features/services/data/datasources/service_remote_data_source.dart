import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/service_model.dart';

final serviceRemoteDataSourceProvider = Provider((ref) => ServiceRemoteDataSource());

class ServiceRemoteDataSource {
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

Future<ServiceModel> createService(ServiceModel service, String token) async {
    final response = await http.post(
      Uri.parse('$baseUrl/'), // POST a /services/
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
}