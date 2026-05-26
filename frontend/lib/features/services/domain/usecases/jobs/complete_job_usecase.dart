import 'package:forja_trabajo/features/services/domain/repositories/service_repository.dart';

class CompleteJobUseCase {
  final ServiceRepository repository;

  CompleteJobUseCase(this.repository);

  Future<bool> execute(String serviceId) async {
    return await repository.completeService(serviceId);
  }
}