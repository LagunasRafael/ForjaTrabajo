import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/service_repository_impl.dart';

// Este provider servirá para gestionar acciones sobre el Job
// Por ahora dejamos la estructura lista para cuando conectemos los botones de "Terminar Trabajo"

final jobRepositoryAccessProvider = Provider((ref) {
  return ref.watch(serviceRepositoryProvider);
});