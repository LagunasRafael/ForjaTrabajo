import '../../repositories/service_repository.dart';

class WithdrawPostulationUseCase {
  final ServiceRepository repository;
  WithdrawPostulationUseCase(this.repository);

  Future<bool> call(String requestId, String token) async {
    return await repository.deletePostulation(requestId, token);
  }
}