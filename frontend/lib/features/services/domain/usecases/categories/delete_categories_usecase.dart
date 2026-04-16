import '../../repositories/service_repository.dart';

class DeleteCategoryUseCase {
  final ServiceRepository repository;
  DeleteCategoryUseCase(this.repository);

  Future<void> call(String id, String token) async {
    await repository.deleteCategory(id, token);
  }
}
