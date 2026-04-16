import 'package:forja_trabajo/features/services/domain/repositories/service_repository.dart';

class CancelServiceUseCase {
  final ServiceRepository repository;

  CancelServiceUseCase(this.repository);

  // 🚀 Le agregamos el String token aquí para que reciba la sesión del usuario
  Future<bool> call(String serviceId, String token) async {
    // Y se lo pasamos al repositorio
    return await repository.cancelService(serviceId, token);
  }
}