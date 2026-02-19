import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/category_entity.dart';
import '../../data/repositories/service_repository_impl.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

final selectedCategoryProvider = StateProvider<String?>((ref) => null);

final categoryListProvider = FutureProvider<List<CategoryEntity>>((ref) async {
  final repository = ref.watch(serviceRepositoryProvider);
  return await repository.getCategories(); 
});

class CategoryActionNotifier extends AutoDisposeNotifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> createCategory(String name, String description) async {
    state = const AsyncLoading();
    try {
      // ✅ USAMOS TU API CLIENT (Igual que en Auth)
      final apiClient = ref.read(apiClientProvider);
      final token = await apiClient.storage.read(key: 'jwt_token') ?? '';

      final repository = ref.read(serviceRepositoryProvider);
      
      // Mandamos los tres datos al repo
      await repository.createCategory(name, description, token);
      
      state = const AsyncData(null);
      ref.invalidate(categoryListProvider); 
      
    } catch (e, stack) {
      state = AsyncError(e, stack);
    }
  }

  Future<void> deleteCategory(String id) async {
    state = const AsyncLoading();
    try {
      // ✅ USAMOS TU API CLIENT PARA SER CONSISTENTES
      final apiClient = ref.read(apiClientProvider);
      final token = await apiClient.storage.read(key: 'jwt_token') ?? '';

      final repository = ref.read(serviceRepositoryProvider);
      await repository.deleteCategory(id, token);
      
      state = const AsyncData(null);
      ref.invalidate(categoryListProvider);
    } catch (e, stack) {
      state = AsyncError(e, stack);
    }
  }
}

final categoryActionProvider = AutoDisposeNotifierProvider<CategoryActionNotifier, AsyncValue<void>>(() {
  return CategoryActionNotifier();
});