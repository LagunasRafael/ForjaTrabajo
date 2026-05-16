import 'package:forja_trabajo/features/services/domain/repositories/service_repository.dart';

class AcceptPostulationUseCase {
  final ServiceRepository repository;

  AcceptPostulationUseCase(this.repository);

  // 🚀 Usamos 'call' y pedimos el token para que sea idéntico a tus otros UseCases
  Future<Map<String, dynamic>> call(String postulationId, String token) async {
    try {
      // OJO: Si tu método en el repositorio no se llama acceptPostulation, 
      // cámbialo aquí por el nombre correcto (ej. acceptWorker, acceptOffer, etc.)
      return await repository.acceptPostulation(postulationId, token);
    } catch (e) {
      print("🚨 Error en AcceptPostulationUseCase: $e");
      throw Exception('Fallo al aceptar la postulación.');
    }
  }
}