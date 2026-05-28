import 'package:shared_preferences/shared_preferences.dart';
import 'package:forja_trabajo/features/services/domain/repositories/service_repository.dart';

class CancelJobUseCase {
  final ServiceRepository repository;

  CancelJobUseCase(this.repository);

  Future<bool> execute(String jobId) async {
    try {
      final job = await repository.cancelJob(jobId, '');
      return job.id.isNotEmpty; 
    } catch (e) {
      print("🚨 Error en CancelJobUseCase: $e");
      return false;
    }
  }
}