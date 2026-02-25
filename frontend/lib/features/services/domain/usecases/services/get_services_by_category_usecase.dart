import '../../entities/service_entity.dart';
import '../../repositories/service_repository.dart';

class GetServicesByCategoryUseCase {
  final ServiceRepository repository;
  GetServicesByCategoryUseCase(this.repository);

  Future<List<ServiceEntity>> call(String categoryId) async {
    return await repository.getServicesByCategory(categoryId);
  }
}