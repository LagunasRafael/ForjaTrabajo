import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forja_trabajo/features/services/domain/repositories/service_repository.dart';
import 'package:forja_trabajo/features/services/data/repositories/service_repository_impl.dart';

class CompleteJobUseCase {
  final ServiceRepository repository;

  CompleteJobUseCase(this.repository);

  Future<bool> execute(String serviceId) async {
    return await repository.completeService(serviceId);
  }
}

final completeJobUseCaseProvider = Provider<CompleteJobUseCase>((ref) {
  final repository = ref.watch(serviceRepositoryProvider);
  return CompleteJobUseCase(repository);
});

final completingJobProvider = StateProvider.family<bool, String>((ref, jobId) => false);