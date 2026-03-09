import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:forja_trabajo/features/services/domain/entities/service_entity.dart';

import '../../data/repositories/service_repository_impl.dart';

final submittedForConfirmationProvider = StateProvider.family<bool, String>((ref, id) => false);

final workerJobsProvider = FutureProvider<List<ServiceEntity>>((ref) async {
  final repo = ref.watch(serviceRepositoryProvider);
  
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token') ?? '';

  if (token.isEmpty) throw Exception("Sesión no encontrada");

  return await repo.getMyApplications(token);
});