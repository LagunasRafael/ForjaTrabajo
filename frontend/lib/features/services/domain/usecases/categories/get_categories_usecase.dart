import '../../entities/category_entity.dart';
import '../../repositories/service_repository.dart';

class GetCategoriesUseCase {
  final ServiceRepository repository;

  GetCategoriesUseCase(this.repository);

  Future<List<CategoryEntity>> call() async {
    return await repository.getCategories();
  }
}