import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';

class AuthRemoteDataSource {
  final ApiClient apiClient;

  // Inyectamos el motor de red que acabas de crear
  AuthRemoteDataSource({required this.apiClient});

  /// Inicia sesión y guarda el JWT en el dispositivo
  Future<String> login(String email, String password) async {
    try {
      // 1. Enviamos un JSON normal (Diccionario) en lugar de FormData
      final response = await apiClient.dio.post(
        '/auth/login', 
        data: {
          'email': email,       // 👈 OJO: Verifica si tu backend espera "email" o "username"
          'password': password,
        },
      );

      // 2. Extraemos el token de la respuesta
      final token = response.data['access_token'];
      
      // 3. Lo guardamos de forma segura
      await apiClient.storage.write(key: 'jwt_token', value: token);
      
      return token;

    } on DioException catch (e) {
      // Manejo de error mejorado para leer el JSON que nos manda FastAPI
      String errorMessage = 'Error desconocido al iniciar sesión';
      
      if (e.response != null && e.response?.data != null) {
        // A veces FastAPI manda el error en "detail"
        if (e.response?.data['detail'] is String) {
          errorMessage = e.response?.data['detail'];
        } else {
          errorMessage = 'Datos incorrectos. Verifica tu correo y contraseña.';
        }
      }
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('Error de conexión: Verifica que el servidor esté encendido.');
    }
  }

  /// Cierra sesión borrando el token
  Future<void> logout() async {
    await apiClient.storage.delete(key: 'jwt_token');
  }
  
  /// Verifica si el usuario ya tiene una sesión activa al abrir la app
  Future<bool> hasValidToken() async {
    final token = await apiClient.storage.read(key: 'jwt_token');
    return token != null && token.isNotEmpty;
  }

  /// Crea una nueva cuenta de usuario en el backend
  Future<void> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    required String role,
  }) async {
    try {
      await apiClient.dio.post(
        '/auth/register', // 👈 Verifica este endpoint con tu compañero de backend
        data: {
          'full_name': fullName, // 👈 Verifica estas llaves con su Schema
          'email': email,
          'phone': phone,
          'password': password,
          'role': role, // ej. 'cliente' o 'trabajador'
        },
      );
      // Si la petición sale bien (200 o 201), no retornamos nada, solo terminamos.
    } on DioException catch (e) {
      // 1. IMPRIMIMOS EL ERROR CRUDO EN LA CONSOLA PARA QUE LO VEAS TÚ
      print('🚨 ERROR 422 DE FASTAPI: ${e.response?.data}');

      String errorMessage = 'Error al crear la cuenta';
      
      if (e.response != null && e.response?.data != null) {
        final detail = e.response?.data['detail'];
        
        // 2. Si FastAPI manda un String normal (ej. "El correo ya existe")
        if (detail is String) {
          errorMessage = detail;
        } 
        // 3. Si FastAPI manda una Lista de errores (Típico del error 422)
        else if (detail is List && detail.isNotEmpty) {
          // Extraemos qué campo falló y por qué
          final campoQueFallo = detail[0]['loc'].last;
          final motivo = detail[0]['msg'];
          errorMessage = 'Error en "$campoQueFallo": $motivo';
        }
      }
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('Error de conexión: Verifica que el servidor esté encendido.');
    }
  }
}