import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
// Importa el provider de la lista de ofertas para poder refrescarlo
import 'service_offers_provider.dart'; 

final serviceRequestProvider = StateNotifierProvider<ServiceRequestController, AsyncValue<void>>((ref) {
  return ServiceRequestController(ref);
});

class ServiceRequestController extends StateNotifier<AsyncValue<void>> {
  final Ref ref;
  ServiceRequestController(this.ref) : super(const AsyncValue.data(null));

  Future<bool> applyToService(String serviceId, String description, double price) async {
    state = const AsyncValue.loading();
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      final url = Uri.parse("http://127.0.0.1:8000/services/service-requests");

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json'
        },
        body: json.encode({
          "service_id": serviceId,
          "description": description,
          "proposed_price": price 
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // 🔥 LA CLAVE: Invalidar la lista de ofertas para ese servicio
        // Esto obliga al cliente a descargar la lista nueva donde YA aparece este worker
        ref.invalidate(offersListProvider(serviceId));
        
        state = const AsyncValue.data(null);
        return true;
      } else {
        final errorBody = json.decode(response.body);
        state = AsyncValue.error(errorBody['detail'] ?? "Error desconocido", StackTrace.current);
        return false;
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}