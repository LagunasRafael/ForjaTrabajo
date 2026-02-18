import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'category_provider.dart';
// IMPORTANTE: Ahora usamos el Repositorio, no el DataSource directo (Clean Architecture)
import '../../data/repositories/service_repository_impl.dart'; 
import '../../domain/entities/service_entity.dart';

// 1. LECTURA: Tu provider original (ahora usando repository para ser consistente)
final serviceListProvider = FutureProvider<List<ServiceEntity>>((ref) async {
  final repository = ref.watch(serviceRepositoryProvider);
  final selectedCatId = ref.watch(selectedCategoryProvider);

  if (selectedCatId == null) {
    return await repository.getServices();
  } else {
    return await repository.getServicesByCategory(selectedCatId);
  }
});

// 2. ESCRITURA: Controlador para crear servicios (Nuevo)
final serviceControllerProvider = StateNotifierProvider<ServiceController, AsyncValue<void>>((ref) {
  return ServiceController(ref);
});

class ServiceController extends StateNotifier<AsyncValue<void>> {
  final Ref ref;
  ServiceController(this.ref) : super(const AsyncValue.data(null));

  Future<void> createService(ServiceEntity service, String token) async {
    state = const AsyncValue.loading(); // Pone la pantalla en carga
    try {
      final repository = ref.read(serviceRepositoryProvider);
      
      // Llamamos al repositorio
      await repository.createService(service, token);
      
      // ¡TRUCO! Refrescamos la lista automáticamente
      ref.invalidate(serviceListProvider); 
      
      state = const AsyncValue.data(null); // Éxito
    } catch (e, st) {
      state = AsyncValue.error(e, st); // Error
    }
  }
}