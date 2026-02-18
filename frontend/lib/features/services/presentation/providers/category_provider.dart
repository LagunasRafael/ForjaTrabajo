import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/category_entity.dart';
import '../../data/repositories/service_repository_impl.dart';

final selectedCategoryProvider = StateProvider<String?>((ref) => null);

// Especificamos que devuelve List<CategoryEntity>
final categoryListProvider = FutureProvider<List<CategoryEntity>>((ref) async {
  final repository = ref.watch(serviceRepositoryProvider);
  // El repositorio debe devolver List<CategoryEntity>
  return await repository.getCategories(); 
});