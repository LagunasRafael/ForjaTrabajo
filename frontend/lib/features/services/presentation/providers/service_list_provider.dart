import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forja_trabajo/features/services/domain/entities/service_entity.dart';
import 'package:forja_trabajo/features/services/data/repositories/service_repository_impl.dart';
import 'category_provider.dart';

// 1. ESTADO DEL BUSCADOR
final searchQueryProvider = StateProvider<String>((ref) => "");

// =======================================================
// 2. PROVIDERS DE LECTURA (UI REACTIVA)
// =======================================================

// A) LISTA PÚBLICA (Home): Filtra por búsqueda > categoría > todo
final serviceListProvider = FutureProvider<List<ServiceEntity>>((ref) async {
  final repository = ref.watch(serviceRepositoryProvider);
  final categoryId = ref.watch(selectedCategoryProvider);
  final query = ref.watch(searchQueryProvider);

  if (query.isNotEmpty) return await repository.searchServices(query);
  if (categoryId != null) return await repository.getServicesByCategory(categoryId);

  return await repository.getServices();
});

// B) DETALLE DE UN SERVICIO (Por ID)
final serviceDetailProvider = FutureProvider.family<ServiceEntity, String>((ref, id) async {
  return await ref.watch(serviceRepositoryProvider).getServiceById(id);
});

// C) MIS TRABAJOS: Lista privada del usuario logueado
final myRequestsProvider = FutureProvider<List<ServiceEntity>>((ref) async {
  return await ref.watch(serviceRepositoryProvider).getMyServices(); 
});

// =======================================================
// 3. CONTROLADOR DE ACCIONES (CREAR / ACTUALIZAR)
// =======================================================

final serviceControllerProvider = StateNotifierProvider<ServiceController, AsyncValue<void>>((ref) {
  return ServiceController(ref);
});

class ServiceController extends StateNotifier<AsyncValue<void>> {
  final Ref ref;
  ServiceController(this.ref) : super(const AsyncValue.data(null));

  // --- CREAR SERVICIO (Soporta imágenes) ---
  Future<void> createService(ServiceEntity service, String token, {List<File>? images}) async {
    state = const AsyncValue.loading();
    try {
      final repository = ref.read(serviceRepositoryProvider);
      
      await repository.createService(service, token, images: images);
      
      // 🧹 LIMPIEZA DE CACHÉ: Forzamos a la app a pedir las listas nuevas
      _invalidateAll();
      
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  // --- ACTUALIZAR SERVICIO ---
  Future<void> updateService(ServiceEntity service, String token) async {
    state = const AsyncValue.loading();
    try {
      await ref.read(serviceRepositoryProvider).updateService(service, token);
      
      // Invalidamos el detalle específico y las listas
      ref.invalidate(serviceDetailProvider(service.id));
      _invalidateAll();
      
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  // Helper privado para no repetir código de invalidación
  void _invalidateAll() {
    ref.invalidate(serviceListProvider); 
    ref.invalidate(myRequestsProvider);
    // Invalidamos categorías por si el conteo de servicios cambió
    ref.invalidate(categoryListProvider);
    ref.invalidate(topCategoryListProvider);
  }
}