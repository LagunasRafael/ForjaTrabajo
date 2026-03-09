import 'package:forja_trabajo/features/services/domain/repositories/service_repository.dart';

class AcceptPostulationUseCase {
  final ServiceRepository repository;

  AcceptPostulationUseCase(this.repository);

  // 🚀 Usamos 'call' y pedimos el token para que sea idéntico a tus otros UseCases
  Future<bool> call(String postulationId, String token) async {
    try {
      // OJO: Si tu método en el repositorio no se llama acceptPostulation, 
      // cámbialo aquí por el nombre correcto (ej. acceptWorker, acceptOffer, etc.)
      await repository.acceptPostulation(postulationId, token);
      return true;
    } catch (e) {
      print("🚨 Error en AcceptPostulationUseCase: $e");
      return false;
    }
  }
}