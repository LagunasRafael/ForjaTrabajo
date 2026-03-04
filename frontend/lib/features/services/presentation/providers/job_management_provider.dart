import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:forja_trabajo/features/services/domain/entities/service_entity.dart';

// 👇 Asegúrate de que esta ruta apunte a tu ServiceRepositoryImpl real
import '../../data/repositories/service_repository_impl.dart';

final workerJobsProvider = FutureProvider<List<ServiceEntity>>((ref) async {
  // 1. Leemos el repositorio
  final repo = ref.watch(serviceRepositoryProvider);
  
  // 2. Sacamos el token
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token') ?? '';

  if (token.isEmpty) throw Exception("Sesión no encontrada");

  // 3. Llamamos a la función que conecta con tu DataSource perfecto
  return await repo.getMyApplications(token);
});