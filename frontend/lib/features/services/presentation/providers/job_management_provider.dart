import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forja_trabajo/features/services/domain/entities/service_entity.dart';

import '../../presentation/providers/service_repository_provider.dart';

final submittedForConfirmationProvider = StateProvider.family<bool, String>((ref, id) => false);

final workerJobsProvider = FutureProvider<List<ServiceEntity>>((ref) async {
  final repo = ref.watch(serviceRepositoryProvider);
  return await repo.getMyApplications();
});