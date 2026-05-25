import 'dart:io';
import '../../entities/service_entity.dart';
import '../../repositories/service_repository.dart';

class CreateServiceUseCase {
  final ServiceRepository repository;

  CreateServiceUseCase(this.repository);

  // 🚀 Cambiamos a Future<ServiceEntity>
  Future<ServiceEntity> execute({
    required ServiceEntity service,
    required String token,
    List<File> images = const [],
  }) async {
    if (service.basePrice < 0) {
      throw Exception("El precio no puede ser negativo");
    }

    // Ahora el retorno coincide con el repositorio
    return await repository.createService(service, token, images: images);
  }
}