import 'package:forja_trabajo/features/services/domain/repositories/service_repository.dart';

class CompleteServiceUseCase {
  final ServiceRepository repository;

  CompleteServiceUseCase(this.repository);

  Future<bool> execute(String serviceId) async {
    return await repository.completeService(serviceId);
  }
}