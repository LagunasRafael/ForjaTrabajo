import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
// ✅ IMPORTA LA ENTIDAD Y EL REPOSITORIO
import 'package:forja_trabajo/features/services/domain/entities/service_request_entity.dart';
import 'package:forja_trabajo/features/services/data/repositories/service_repository_impl.dart';

// 1. Provider de la lista (Usa ServiceRequestEntity)
final offersListProvider = FutureProvider.family<List<ServiceRequestEntity>, String>((ref, serviceId) async {
  final repository = ref.watch(serviceRepositoryProvider);
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token') ?? '';

  return repository.getOffers(serviceId, token);
});

// 2. Controller para aceptar (Asegúrate de que no haya lógica duplicada aquí)
final acceptOfferProvider = StateNotifierProvider<AcceptOfferController, AsyncValue<void>>((ref) {
  return AcceptOfferController(ref);
});

class AcceptOfferController extends StateNotifier<AsyncValue<void>> {
  final Ref ref;
  AcceptOfferController(this.ref) : super(const AsyncValue.data(null));

  Future<bool> acceptWorker(String requestId) async {
    state = const AsyncValue.loading();
    try {
      final repository = ref.read(serviceRepositoryProvider);
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      if (token.isEmpty) throw Exception("Token no encontrado");

      // Llamada al repositorio
      await repository.acceptPostulation(requestId, token);
      
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      // 👇 ESTO TE DIRÁ EL ERROR REAL EN LA CONSOLA
      print("🚨 ERROR EN ACCEPT_WORKER: $e");
      print("📌 STACKTRACE: $st");
      
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}