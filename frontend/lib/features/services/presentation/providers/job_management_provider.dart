import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forja_trabajo/features/services/domain/entities/service_entity.dart';

import '../../data/repositories/service_repository_impl.dart';

final submittedForConfirmationProvider = StateProvider.family<bool, String>((ref, id) => false);

final workerJobsProvider = FutureProvider<List<ServiceEntity>>((ref) async {
  final repo = ref.watch(serviceRepositoryProvider);
  return await repo.getMyApplications();
});