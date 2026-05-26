import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forja_trabajo/features/services/domain/usecases/jobs/complete_job_usecase.dart';
import 'package:forja_trabajo/features/services/data/repositories/service_repository_impl.dart';

final completeJobUseCaseProvider = Provider<CompleteJobUseCase>((ref) {
  final repository = ref.watch(serviceRepositoryProvider);
  return CompleteJobUseCase(repository);
});

final completingJobProvider = StateProvider.family<bool, String>((ref, jobId) => false);
