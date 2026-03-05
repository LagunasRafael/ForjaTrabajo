import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/job_model.dart';
import '../../../../core/network/api_client.dart';

final jobRemoteDataSourceProvider = Provider((ref) {
  final apiClient = ApiClient();
  return JobRemoteDataSource(apiClient);
});

class JobRemoteDataSource {
  final ApiClient _apiClient;

  JobRemoteDataSource(this._apiClient);

  String get baseUrl => '${_apiClient.dio.options.baseUrl}/services/jobs';

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
