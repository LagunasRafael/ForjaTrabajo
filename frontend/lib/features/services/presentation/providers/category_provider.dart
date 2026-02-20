import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/category_entity.dart';
import '../../data/repositories/service_repository_impl.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

final selectedCategoryProvider = StateProvider<String?>((ref) => null);

// 1. PROVEEDOR ORIGINAL: Trae TODAS las categorías (para el menú "Ver todas")
final categoryListProvider = FutureProvider<List<CategoryEntity>>((ref) async {
  final repository = ref.watch(serviceRepositoryProvider);
  return await repository.getCategories(); 
});

// 👇 2. NUEVO PROVEEDOR: Trae SOLO EL TOP 5 (para el carrusel principal)
final topCategoryListProvider = FutureProvider<List<CategoryEntity>>((ref) async {
  final repository = ref.watch(serviceRepositoryProvider);
  return await repository.getTopCategories(); // Llama a la nueva función
});

class CategoryActionNotifier extends AutoDisposeNotifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> createCategory(String name, String description) async {
    state = const AsyncLoading();
    try {
      final apiClient = ref.read(apiClientProvider);
      final token = await apiClient.storage.read(key: 'jwt_token') ?? '';

      final repository = ref.read(serviceRepositoryProvider);
      await repository.createCategory(name, description, token);
      
      state = const AsyncData(null);
      // 👇 Refrescamos ambos proveedores para que la nueva categoría aparezca
      ref.invalidate(categoryListProvider); 
      ref.invalidate(topCategoryListProvider); 
      
    } catch (e, stack) {
      state = AsyncError(e, stack);
    }
  }

  Future<void> deleteCategory(String id) async {
    state = const AsyncLoading();
    try {
      final apiClient = ref.read(apiClientProvider);
      final token = await apiClient.storage.read(key: 'jwt_token') ?? '';

      final repository = ref.read(serviceRepositoryProvider);
      await repository.deleteCategory(id, token);
      
      state = const AsyncData(null);
      // 👇 Refrescamos ambos proveedores
      ref.invalidate(categoryListProvider);
      ref.invalidate(topCategoryListProvider);
    } catch (e, stack) {
      state = AsyncError(e, stack);
    }
  }
}

final categoryActionProvider = AutoDisposeNotifierProvider<CategoryActionNotifier, AsyncValue<void>>(() {
  return CategoryActionNotifier();
});