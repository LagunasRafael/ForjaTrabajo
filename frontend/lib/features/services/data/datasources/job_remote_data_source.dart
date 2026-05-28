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

  Future<JobModel> completeJob(String jobId, String token) async {
    try {
      final response = await _apiClient.dio.put('/services/jobs/$jobId/complete');
      return JobModel.fromJson(response.data);
    } on Exception catch (e) {
      throw Exception('Fallo al completar el trabajo: $e');
    }
  }

  Future<JobModel> cancelJob(String jobId, String token) async {
    try {
      final response = await _apiClient.dio.put('/services/jobs/$jobId/cancel');
      return JobModel.fromJson(response.data);
    } on Exception catch (e) {
      throw Exception('Fallo al cancelar el trabajo: $e');
    }
  }
}
