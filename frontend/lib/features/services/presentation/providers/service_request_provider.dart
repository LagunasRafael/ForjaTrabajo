import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/service_request_entity.dart';
import '../../domain/usecases/service_requests/create_postulation_usecase.dart';
import '../../domain/usecases/service_requests/update_postulation_usecase.dart';
import '../../domain/usecases/service_requests/withdraw_postulation_usecase.dart';

import '../../domain/usecases/service_requests/accept_postulation_usecase.dart'; 

import '../../data/repositories/service_repository_impl.dart';
import 'service_offers_provider.dart'; 

final createPostulationProvider = Provider((ref) => CreatePostulationUseCase(ref.watch(serviceRepositoryProvider)));
final updatePostulationProvider = Provider((ref) => UpdatePostulationUseCase(ref.watch(serviceRepositoryProvider)));
final withdrawPostulationProvider = Provider((ref) => WithdrawPostulationUseCase(ref.watch(serviceRepositoryProvider)));
final acceptPostulationProvider = Provider((ref) => AcceptPostulationUseCase(ref.watch(serviceRepositoryProvider)));

final isAcceptingProvider = StateProvider.family<bool, String>((ref, id) => false);

final serviceRequestProvider = StateNotifierProvider<ServiceRequestController, AsyncValue<void>>((ref) {
  return ServiceRequestController(ref);
});

class ServiceRequestController extends StateNotifier<AsyncValue<void>> {
  final Ref ref;
  ServiceRequestController(this.ref) : super(const AsyncValue.data(null));

  Future<bool> applyToService(String serviceId, String description, double price) async {
    state = const AsyncValue.loading();
    try {
      final token = await _getToken();
      final newRequest = ServiceRequestEntity(
        id: '', serviceId: serviceId, workerId: '', description: description, proposedPrice: price, status: 'pending', createdAt: DateTime.now(),
      );

      await ref.read(createPostulationProvider).call(newRequest, token);
      ref.invalidate(offersListProvider(serviceId)); 
      
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }  

  Future<bool> updateApplication(String requestId, String description, double price) async {
    state = const AsyncValue.loading(); 
    try {
      final token = await _getToken();
      final success = await ref.read(updatePostulationProvider).call(requestId, description, price, token);
      state = const AsyncValue.data(null); 
      return success;
    } catch (e, st) {
      state = AsyncValue.error(e, st); 
      return false;
    }
  }

  Future<bool> withdrawApplication(String requestId) async {
    state = const AsyncValue.loading();
    try {
      final token = await _getToken(); 
      await ref.read(withdrawPostulationProvider).call(requestId, token);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> acceptWorker(String requestId) async {
    state = const AsyncValue.loading();
    try {
      final token = await _getToken(); 
      
      await ref.read(acceptPostulationProvider).call(requestId, token);
      
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    if (token.isEmpty) throw Exception("Token no encontrado");
    return token;
  }
}