import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forja_trabajo/features/services/domain/entities/service_entity.dart';
import 'package:forja_trabajo/features/services/data/repositories/service_repository_impl.dart';
import 'package:forja_trabajo/features/services/domain/usecases/services/create_services_usecase.dart';
import 'package:forja_trabajo/features/services/domain/usecases/services/cancel_service_usecase.dart';
import 'package:forja_trabajo/features/auth/presentation/providers/auth_provider.dart';
import 'package:forja_trabajo/shared/widgets/location/marketplace_location_storage.dart';
import 'category_provider.dart';

final searchQueryProvider = StateProvider<String>((ref) => "");

final selectedRadiusKmProvider = StateProvider<double>((ref) => 25.0);

final selectedMarketplaceLatitudeProvider = StateProvider<double?>((ref) => null);
final selectedMarketplaceLongitudeProvider = StateProvider<double?>((ref) => null);
final selectedMarketplaceLocationLabelProvider = StateProvider<String?>((ref) => null);
final isLocatingMarketplaceProvider = StateProvider<bool>((ref) => false);

final useMarketplaceLocationFilterProvider = StateProvider<bool>((ref) => true);

final marketplaceLocationInitializedProvider = StateProvider<bool>((ref) => false);

final marketplaceLocationInitProvider = FutureProvider<void>((ref) async {
  if (ref.read(marketplaceLocationInitializedProvider)) return;

  final data = await MarketplaceLocationStorage.loadAll();

  if (data.filterEnabled) {
    if (data.latitude != null && data.longitude != null) {
      ref.read(selectedMarketplaceLatitudeProvider.notifier).state = data.latitude;
      ref.read(selectedMarketplaceLongitudeProvider.notifier).state = data.longitude;
      ref.read(selectedMarketplaceLocationLabelProvider.notifier).state = data.label;
    }
  }

  ref.read(selectedRadiusKmProvider.notifier).state = data.radius;
  ref.read(useMarketplaceLocationFilterProvider.notifier).state = data.filterEnabled;
  ref.read(marketplaceLocationInitializedProvider.notifier).state = true;
});

final createServiceUseCaseProvider = Provider((ref) {
  final repository = ref.watch(serviceRepositoryProvider);
  return CreateServiceUseCase(repository);
});

final cancelServiceUseCaseProvider = Provider((ref) {
  final repository = ref.watch(serviceRepositoryProvider);
  return CancelServiceUseCase(repository);
});

// =======================================================
// 3. PROVIDERS DE LECTURA (UI REACTIVA)
// =======================================================

final serviceListProvider = FutureProvider<List<ServiceEntity>>((ref) async {
  final repository = ref.watch(serviceRepositoryProvider);
  final categoryId = ref.watch(selectedCategoryProvider);
  final query = ref.watch(searchQueryProvider);
  final authState = ref.read(authProvider);
  final radiusKm = ref.watch(selectedRadiusKmProvider);
  final useFilter = ref.watch(useMarketplaceLocationFilterProvider);

  final marketplaceLat = ref.watch(selectedMarketplaceLatitudeProvider);
  final marketplaceLng = ref.watch(selectedMarketplaceLongitudeProvider);
  final user = authState.user;

  final double? lat;
  final double? lng;
  final double? radius;

  if (!useFilter) {
    lat = null;
    lng = null;
    radius = null;
  } else {
    lat = marketplaceLat ?? user?.latitude;
    lng = marketplaceLng ?? user?.longitude;
    radius = (lat != null && lng != null) ? radiusKm : null;
  }

  return await repository.getServices(
    categoryId: categoryId,
    query: query.isNotEmpty ? query : null,
    latitude: lat,
    longitude: lng,
    radiusKm: radius,
  );
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