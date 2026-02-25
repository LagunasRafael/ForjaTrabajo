import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/service_request_entity.dart';
import '../../data/repositories/service_repository_impl.dart';
// Aquí importarías: PostulateToServiceUseCase, GetServiceOffersUseCase

// Provider para ver las ofertas de un servicio (como Cliente)
final serviceOffersProvider = FutureProvider.family<List<ServiceRequestEntity>, String>((ref, serviceId) async {
  final repository = ref.watch(serviceRepositoryProvider);
  // Asumimos que tienes el token guardado en algún lado, por ahora hardcodeado o null
  // Lo ideal es leerlo de un authProvider
  const fakeToken = "token_de_prueba"; 
  return await repository.getOffers(serviceId, fakeToken);
});

// Nota: Para CREAR una postulación (POST), generalmente usamos un StateNotifier, 
// pero eso lo veremos cuando hagamos la pantalla de postulación.