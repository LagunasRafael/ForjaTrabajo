import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'category_provider.dart';
import '../../data/repositories/service_repository_impl.dart'; 
import '../../domain/entities/service_entity.dart';
import 'dart:io';


// 1. EL BUSCADOR: Estado para la barra de búsqueda
final searchQueryProvider = StateProvider<String>((ref) => "");

// 2. LA LISTA: Un solo provider que maneja TODO (Busqueda, Filtro y Carga inicial)
final serviceListProvider = FutureProvider<List<ServiceEntity>>((ref) async {
  final repository = ref.watch(serviceRepositoryProvider);
  final categoryId = ref.watch(selectedCategoryProvider);
  final query = ref.watch(searchQueryProvider); 

  // PRIORIDAD 1: Si el usuario escribe en la barra, buscamos en el backend
  if (query.isNotEmpty) {
    return await repository.searchServices(query);
  }
  
  // PRIORIDAD 2: Si no hay búsqueda pero seleccionó categoría, filtramos
  if (categoryId != null) {
    return await repository.getServicesByCategory(categoryId);
  }

  // POR DEFECTO: Traemos todos los servicios
  return await repository.getServices();
});

// 3. CONTROLADOR: Para crear nuevos servicios (POST)
final serviceControllerProvider = StateNotifierProvider<ServiceController, AsyncValue<void>>((ref) {
  return ServiceController(ref);
});

class ServiceController extends StateNotifier<AsyncValue<void>> {
  final Ref ref;
  ServiceController(this.ref) : super(const AsyncValue.data(null));

  Future<void> createService(ServiceEntity service, String token, {List<File>? images}) async {
    state = const AsyncValue.loading();
    try {
      print("🟢 CONTROLLER: Iniciando petición de creación...");
      final repository = ref.read(serviceRepositoryProvider);
      
      await repository.createService(service, token, images: images);
      print("🟢 CONTROLLER: ¡Servicio creado en el backend con éxito!");
      
      print("🟢 CONTROLLER: Actualizando estado a completado...");
      state = const AsyncValue.data(null);

    } catch (e, st) {
      // 👇 Si el error pasa aquí, lo atraparemos
      print("🔴 ERROR EN EL CONTROLLER: $e");
      print("🔴 STACKTRACE: $st");
      state = AsyncValue.error(e, st);
    }
  }
}