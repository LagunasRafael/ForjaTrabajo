import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forja_trabajo/features/services/domain/usecases/jobs/cancel_job_usecase.dart';
import 'package:forja_trabajo/features/services/presentation/providers/service_repository_provider.dart';

final cancelJobUseCaseProvider = Provider<CancelJobUseCase>((ref) {
  final repository = ref.read(serviceRepositoryProvider);
  return CancelJobUseCase(repository);
});
