import 'package:shared_preferences/shared_preferences.dart';
import 'package:forja_trabajo/features/services/domain/repositories/service_repository.dart';

class CancelJobUseCase {
  final ServiceRepository repository;

  CancelJobUseCase(this.repository);

  Future<bool> execute(String jobId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      if (token.isEmpty) return false;
      final job = await repository.cancelJob(jobId, token);
      return job.id.isNotEmpty; 
    } catch (e) {
      print("🚨 Error en CancelJobUseCase: $e");
      return false;
    }
  }
}