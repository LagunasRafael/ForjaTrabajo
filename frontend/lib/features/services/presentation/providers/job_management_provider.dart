import 'package:flutter_riverpod/flutter_riverpod.dart';
// Importa tu repositorio real
import '../../data/repositories/service_repository_impl.dart';

// 1. Acceso al repositorio
final jobRepositoryAccessProvider = Provider((ref) {
  // Asegúrate de que serviceRepositoryProvider esté definido en tu repository_impl
  return ref.watch(serviceRepositoryProvider);
});

// 2. El provider que carga la lista de trabajos (FutureProvider)
final jobManagementProvider = FutureProvider((ref) async {
  final repo = ref.watch(jobRepositoryAccessProvider);
  
  // Aquí llamamos al método de tu repositorio que obtiene los trabajos.
  // Ajusta el nombre del método (ej: getMyJobs) según tu ServiceRepository.
  return await repo.getServices(); 
});