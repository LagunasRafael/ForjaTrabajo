import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forja_trabajo/features/services/domain/entities/service_entity.dart';
// Asegúrate de importar el repositorio correcto
import 'package:forja_trabajo/features/services/data/repositories/service_repository_impl.dart';
import 'category_provider.dart';

// 1. EL BUSCADOR (Estado simple)
final searchQueryProvider = StateProvider<String>((ref) => "");

// =======================================================
// 2. LISTAS DE LECTURA (GET)
// =======================================================

// A) LISTA PÚBLICA (Para el Home)
// Filtra por búsqueda o categoría, si no hay filtros, trae todo.
final serviceListProvider = FutureProvider<List<ServiceEntity>>((ref) async {
  final repository = ref.watch(serviceRepositoryProvider);
  final categoryId = ref.watch(selectedCategoryProvider); // Filtro Categoría
  final query = ref.watch(searchQueryProvider);           // Filtro Buscador


  // Prioridad 1: Búsqueda
  if (query.isNotEmpty) {
    return await repository.searchServices(query);
  }
  
  // Prioridad 2: Filtro por categoría
  if (categoryId != null) {
    return await repository.getServicesByCategory(categoryId);
  }

  // Por defecto: Todo lo abierto
  return await repository.getServices();
});

// Este debe estar al nivel superior del archivo, no dentro de una clase
final serviceDetailProvider = FutureProvider.family<ServiceEntity, String>((ref, serviceId) async {
  final repository = ref.watch(serviceRepositoryProvider);
  return await repository.getServiceById(serviceId);
});

// B) LISTA PRIVADA (Para "Mis Trabajos") ✅ ESTA ES LA QUE TE FALTABA
// Trae solo los trabajos creados por mí (Abiertos, En Proceso, Finalizados)
final myRequestsProvider = FutureProvider<List<ServiceEntity>>((ref) async {
  final repository = ref.watch(serviceRepositoryProvider);
  return repository.getMyServices(); 
});

// =======================================================
// 3. EL CONTROLADOR (ACCIONES: Crear, Actualizar)
// =======================================================

final serviceControllerProvider = StateNotifierProvider<ServiceController, AsyncValue<void>>((ref) {
  return ServiceController(ref);
});

class ServiceController extends StateNotifier<AsyncValue<void>> {
  final Ref ref;

  ServiceController(this.ref) : super(const AsyncValue.data(null));

  Future<void> createService(ServiceEntity service, String token) async {
    state = const AsyncValue.loading();
    try {
      final repository = ref.read(serviceRepositoryProvider);
      
      await repository.createService(service, token);
      
      ref.invalidate(serviceListProvider);     
      ref.invalidate(topCategoryListProvider);  
      ref.invalidate(categoryListProvider);     
      
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  // --- ACTUALIZAR ---
  Future<void> updateService(ServiceEntity service, String token) async {
    state = const AsyncValue.loading();
    try {
      final repository = ref.read(serviceRepositoryProvider);
      
      // Llamamos al repositorio
      await repository.updateService(service, token);
      
      // Refrescamos las listas para ver los cambios reflejados
      ref.invalidate(serviceListProvider); 
      ref.invalidate(myRequestsProvider); 
      
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
