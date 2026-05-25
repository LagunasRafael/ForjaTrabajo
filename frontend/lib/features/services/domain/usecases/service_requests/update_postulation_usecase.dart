import '../../repositories/service_repository.dart';

class UpdatePostulationUseCase {
  final ServiceRepository repository;
  UpdatePostulationUseCase(this.repository);

  Future<bool> call(String requestId, String description, double price, String token) async {
    return await repository.updatePostulation(requestId, description, price, token);
  }
}