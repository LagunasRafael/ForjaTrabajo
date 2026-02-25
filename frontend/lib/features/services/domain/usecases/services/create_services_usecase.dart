import '../../entities/service_entity.dart';
import '../../repositories/service_repository.dart';

class CreateServiceUseCase {
  final ServiceRepository repository;

  CreateServiceUseCase(this.repository);

  Future<ServiceEntity> execute(ServiceEntity service, String token) {
    return repository.createService(service, token);
  }
}