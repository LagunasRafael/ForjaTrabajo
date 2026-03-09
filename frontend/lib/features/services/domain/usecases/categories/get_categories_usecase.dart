import '../../domain/repositories/service_repository.dart';
import '../../domain/entities/category_entity.dart';

class GetCategoriesUseCase {
  final ServiceRepository repository;
  GetCategoriesUseCase(this.repository);

  Future<List<CategoryEntity>> call() async {
    return await repository.getCategories();
  }
}