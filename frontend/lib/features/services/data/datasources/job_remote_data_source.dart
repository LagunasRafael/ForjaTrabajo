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
  final http.Client _httpClient;

  JobRemoteDataSource(this._apiClient, {http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  String get baseUrl => '${_apiClient.dio.options.baseUrl}/services/jobs';

  Future<JobModel> completeJob(String jobId, String token) async {
    final url = Uri.parse('$baseUrl/$jobId/complete');

    print("📡 Intentando conectar a: $url");

    final response = await _httpClient
        .put(
          url,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode == 200 || response.statusCode == 201) {
      return JobModel.fromJson(json.decode(response.body));
    } else {
      throw Exception('Error: ${response.statusCode} - ${response.body}');
    }
  }

  Future<JobModel> cancelJob(String jobId, String token) async {
    final response = await _httpClient
        .put(
          Uri.parse('$baseUrl/$jobId/cancel'),
          headers: {'Authorization': 'Bearer $token'},
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return JobModel.fromJson(json.decode(response.body));
    } else {
      throw Exception('Error cancelando trabajo');
    }
  }
}
