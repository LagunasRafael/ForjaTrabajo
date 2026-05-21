import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forja_trabajo/features/services/domain/entities/service_entity.dart';
import 'package:forja_trabajo/features/services/data/repositories/service_repository_impl.dart';
import 'package:forja_trabajo/features/services/domain/usecases/services/create_services_usecase.dart';
import 'package:forja_trabajo/features/services/domain/usecases/services/delete_services_usecase.dart';
import 'package:forja_trabajo/features/services/domain/usecases/services/update_service_usecase.dart';
import 'package:forja_trabajo/features/services/domain/usecases/services/cancel_service_usecase.dart'; 
import 'category_provider.dart';

final searchQueryProvider = StateProvider<String>((ref) => "");

final createServiceUseCaseProvider = Provider((ref) {
  final repository = ref.watch(serviceRepositoryProvider);
  return CreateServiceUseCase(repository);
});

final cancelServiceUseCaseProvider = Provider((ref) {
  final repository = ref.watch(serviceRepositoryProvider);
  return CancelServiceUseCase(repository);
});

// Podrías crear uno para Update también si quieres ser 100% estricto
// final updateServiceUseCaseProvider = Provider((ref) => UpdateServiceUseCase(ref.watch(serviceRepositoryProvider)));

// =======================================================
// 3. PROVIDERS DE LECTURA (UI REACTIVA)
// =======================================================

final serviceListProvider = FutureProvider<List<ServiceEntity>>((ref) async {
  final repository = ref.watch(serviceRepositoryProvider);
  final categoryId = ref.watch(selectedCategoryProvider);
  final query = ref.watch(searchQueryProvider);

  if (query.isNotEmpty && categoryId != null) {
    return await repository.getServices(categoryId: categoryId, query: query);
  }
  if (query.isNotEmpty) return await repository.searchServices(query);
  if (categoryId != null) return await repository.getServicesByCategory(categoryId);

  return await repository.getServices();
});

final serviceDetailProvider = FutureProvider.family<ServiceEntity, String>((ref, id) async {
  return await ref.watch(serviceRepositoryProvider).getServiceById(id);
});

final myRequestsProvider = FutureProvider<List<ServiceEntity>>((ref) async {
  return await ref.watch(serviceRepositoryProvider).getMyServices(); 
});

// =======================================================
// 4. CONTROLADOR DE ACCIONES
// =======================================================

final serviceControllerProvider = StateNotifierProvider<ServiceController, AsyncValue<void>>((ref) {
  final createUseCase = ref.watch(createServiceUseCaseProvider);
  // 🚀 3. INYECTAMOS EL CANCEL USECASE AL CONTROLADOR
  final cancelUseCase = ref.watch(cancelServiceUseCaseProvider);
  return ServiceController(ref, createUseCase, cancelUseCase);
});

class ServiceController extends StateNotifier<AsyncValue<void>> {
  final Ref ref;
  final CreateServiceUseCase _createUseCase;
  // 🚀 4. LO RECIBIMOS EN LA CLASE
  final CancelServiceUseCase _cancelUseCase;

  ServiceController(this.ref, this._createUseCase, this._cancelUseCase) : super(const AsyncValue.data(null));

  // --- CREAR SERVICIO ---
  Future<void> createService(ServiceEntity service, String token, {List<File>? images}) async {
    state = const AsyncValue.loading();
    try {
      await _createUseCase.execute(
        service: service, 
        token: token, 
        images: images ?? []
      );
      
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
      
      ref.invalidate(serviceDetailProvider(service.id));
      _invalidateAll();
      
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  // 🚀 5. LA FUNCIÓN QUE LLAMA LA "X" ROJA
  Future<void> cancelService(String serviceId, String token) async {
    state = const AsyncValue.loading();
    try {
      await _cancelUseCase.call(serviceId, token);
      
      // Esto actualizará la lista de "Mis solicitudes" automáticamente
      _invalidateAll();
      
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void _invalidateAll() {
    ref.invalidate(serviceListProvider); 
    ref.invalidate(myRequestsProvider);
    ref.invalidate(categoryListProvider);
    ref.invalidate(topCategoryListProvider);
  }
}