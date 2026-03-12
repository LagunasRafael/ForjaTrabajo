import '../../repositories/service_repository.dart';

class CreateCategoryUseCase {
  final ServiceRepository repository;
  CreateCategoryUseCase(this.repository);

  Future<void> call(String name, String description, String token) async {
    // Si mañana quieres agregar una regla de negocio (ej. que el nombre no tenga groserías),
    // la pones aquí, sin tocar la interfaz gráfica.
    if (name.isEmpty) throw Exception("El nombre no puede estar vacío");

    await repository.createCategory(name, description, token);
  }
}
