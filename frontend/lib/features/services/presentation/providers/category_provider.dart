import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/repositories/service_repository.dart';
import '../../presentation/providers/service_repository_provider.dart';

// 1. Estado de la categoría seleccionada
final selectedCategoryProvider = StateProvider<String?>((ref) => null);

// 2. Traer TODAS las categorías
final categoryListProvider = FutureProvider<List<CategoryEntity>>((ref) async {
  final repository = ref.watch(serviceRepositoryProvider);
  return await repository.getCategories(); 
});

// 3. Traer el TOP 5
final topCategoryListProvider = FutureProvider<List<CategoryEntity>>((ref) async {
  final repository = ref.watch(serviceRepositoryProvider);
  return await repository.getTopCategories(); 
});

// 4. Acciones de Categoría (Crear/Eliminar) - Restaurado para el Admin
class CategoryActionNotifier extends StateNotifier<AsyncValue<void>> {
  final ServiceRepository repository;
  final Ref ref;

  CategoryActionNotifier(this.repository, this.ref) : super(const AsyncValue.data(null));

  Future<void> createCategory(String name, String desc) async {
    state = const AsyncValue.loading();
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      await repository.createCategory(name, desc, token);
      
      // Refrescar la lista de categorías
      ref.invalidate(categoryListProvider);
      
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> deleteCategory(String id) async {
    state = const AsyncValue.loading();
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      await repository.deleteCategory(id, token);
      
      // Refrescar la lista de categorías
      ref.invalidate(categoryListProvider);
      
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

final categoryActionProvider = StateNotifierProvider<CategoryActionNotifier, AsyncValue<void>>((ref) {
  final repository = ref.watch(serviceRepositoryProvider);
  return CategoryActionNotifier(repository, ref);
});

