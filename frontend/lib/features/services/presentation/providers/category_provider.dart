import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/category_entity.dart';
import '../../data/repositories/service_repository_impl.dart';

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

// ¡Y LISTO! Borramos el CategoryActionNotifier porque el cliente no crea categorías.