import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/job_model.dart';

final jobRemoteDataSourceProvider = Provider((ref) => JobRemoteDataSource());

class JobRemoteDataSource {
  //final String baseUrl = "http://127.0.0.1:8000/services/jobs"; // Ajusta según tu router prefix
  final String baseUrl = "http://10.0.2.2:8000/services/jobs";

  Future<JobModel> completeJob(String jobId, String token) async {
    final url = Uri.parse('$baseUrl/$jobId/complete'); 

    print("📡 Intentando conectar a: $url"); // Esto te confirmará si ya se ve bien

    final response = await http.put(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return JobModel.fromJson(json.decode(response.body));
    } else {
      throw Exception('Error: ${response.statusCode} - ${response.body}');
    }
}

  Future<JobModel> cancelJob(String jobId, String token) async {
    final response = await http.put(
      Uri.parse('$baseUrl/$jobId/cancel'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return JobModel.fromJson(json.decode(response.body));
    } else {
      throw Exception('Error cancelando trabajo');
    }
  }
}