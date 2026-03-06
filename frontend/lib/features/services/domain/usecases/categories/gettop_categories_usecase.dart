import '../../domain/repositories/service_repository.dart';
import '../../domain/entities/category_entity.dart';

class GetTopCategoriesUseCase {
  final ServiceRepository repository;
  GetTopCategoriesUseCase(this.repository);

  Future<List<CategoryEntity>> call() async {
    return await repository.getTopCategories();
  }
}