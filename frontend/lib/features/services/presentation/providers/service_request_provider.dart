import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:forja_trabajo/features/auth/presentation/providers/auth_provider.dart';
import '../../../../core/network/api_client.dart'; // 👈 Asegúrate que la ruta sea correcta
import 'service_offers_provider.dart'; 

final serviceRequestProvider = StateNotifierProvider<ServiceRequestController, AsyncValue<void>>((ref) {
  // Obtenemos el cliente de red global
  final apiClient = ref.watch(apiClientProvider); 
  return ServiceRequestController(ref, apiClient);
});

class ServiceRequestController extends StateNotifier<AsyncValue<void>> {
  final Ref ref;
  final ApiClient apiClient;

  ServiceRequestController(this.ref, this.apiClient) : super(const AsyncValue.data(null));

  Future<bool> applyToService(String serviceId, String description, double price) async {
    state = const AsyncValue.loading();
    try {
      // 🚀 USAMOS DIO PARA QUE SEA COMPATIBLE CON TU BACKEND
      await apiClient.dio.post(
        '/services/service-requests', 
        data: {
          "service_id": serviceId,
          "description": description,
          "proposed_price": price 
        },
      );

      // 🔥 Refrescamos la lista para que el cliente vea que ya te postulaste
      ref.invalidate(offersListProvider(serviceId));
      
      state = const AsyncValue.data(null);
      return true;
      
    } on DioException catch (e) {
      final errorMsg = e.response?.data['detail'] ?? "Error al enviar postulación";
      state = AsyncValue.error(errorMsg, StackTrace.current);
      return false;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}