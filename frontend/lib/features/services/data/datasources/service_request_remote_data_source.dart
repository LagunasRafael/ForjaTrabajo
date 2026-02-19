import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/service_request_model.dart';
import '../models/job_model.dart'; // Importante para acceptPostulation

final serviceRequestRemoteDataSourceProvider = Provider((ref) => ServiceRequestRemoteDataSource());

class ServiceRequestRemoteDataSource {
  final String baseUrl = "http://127.0.0.1:8000/services"; 

  // Worker se postula
  Future<ServiceRequestModel> createRequest(ServiceRequestModel request, String token) async {
    final response = await http.post(
      Uri.parse('$baseUrl/service-requests'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(request.toJson()),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return ServiceRequestModel.fromJson(json.decode(response.body));
    } else {
      throw Exception('Error al postularse');
    }
  }

  // Cliente ve ofertas
  Future<List<ServiceRequestModel>> getOffers(String serviceId, String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/$serviceId/offers'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((e) => ServiceRequestModel.fromJson(e)).toList();
    } else {
      throw Exception('Error obteniendo ofertas');
    }
  }

  // Cliente acepta oferta -> Retorna un Job
  Future<JobModel> acceptPostulation(String requestId, String token) async {
    final response = await http.post(
      Uri.parse('$baseUrl/accept-postulation/$requestId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return JobModel.fromJson(json.decode(response.body));
    } else {
      throw Exception('Error al aceptar postulación');
    }
  }
}