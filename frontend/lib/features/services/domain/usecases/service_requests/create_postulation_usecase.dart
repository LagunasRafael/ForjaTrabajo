import '../../repositories/service_repository.dart';
import '../../entities/service_request_entity.dart';

class CreatePostulationUseCase {
  final ServiceRepository repository;
  CreatePostulationUseCase(this.repository);

  Future<void> call(ServiceRequestEntity request, String token) async {
    await repository.createRequest(request, token);
  }
}