import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/job_model.dart';

final jobRemoteDataSourceProvider = Provider((ref) => JobRemoteDataSource());

class JobRemoteDataSource {
  final String baseUrl = "http://127.0.0.1:8000/services/jobs"; // Ajusta según tu router prefix
  //final String baseUrl = "http://10.0.2.2:8000/services/jobs";

  Future<JobModel> completeJob(String jobId, String token) async {
    final response = await http.put(
      Uri.parse('$baseUrl/$jobId/complete'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return JobModel.fromJson(json.decode(response.body));
    } else {
      throw Exception('Error completando trabajo');
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