import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  final Dio dio;
  final FlutterSecureStorage storage;

  // Constructor
  ApiClient()
      : dio = Dio(
          BaseOptions(
            // OJO: Esta URL cambiará dependiendo de Project IDX. 
            // Por ahora ponemos la estándar de FastAPI local.
            baseUrl: 'http://127.0.0.1:8000', 
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          ),
        ),
        storage = const FlutterSecureStorage() {
    _initializeInterceptors();
  }

  // --- EL INTERCEPTOR MÁGICO ---
  void _initializeInterceptors() {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // 1. Antes de que el mensaje salga del celular, buscamos el Token
          final token = await storage.read(key: 'jwt_token');
          
          // 2. Si el usuario ya hizo login y tiene token, se lo pegamos en la cabecera
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          
          // 3. Dejamos que el mensaje continúe su camino al backend
          return handler.next(options);
        },
        onError: (DioException e, handler) async {
          // Si el backend nos responde con 401 (No Autorizado / Token Expirado)
          if (e.response?.statusCode == 401) {
            // Borramos el token caducado
            await storage.delete(key: 'jwt_token');
            
            // TODO: Aquí luego pondremos código para mandar al usuario a la pantalla de Login
            print('🚨 Token expirado. Cerrando sesión...');
          }
          return handler.next(e);
        },
      ),
    );
  }
}