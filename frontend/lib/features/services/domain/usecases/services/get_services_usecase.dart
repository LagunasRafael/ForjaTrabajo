import '../../entities/service_entity.dart';
import '../../repositories/service_repository.dart';

class GetServicesUseCase {
  final ServiceRepository repository;

  GetServicesUseCase(this.repository);

  Future<List<ServiceEntity>> call() async {
    return await repository.getServices();
  }
}