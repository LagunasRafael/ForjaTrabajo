import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/models/user_model.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class AuthRemoteDataSource {
  final ApiClient apiClient;

  // Inyectamos el motor de red que acabas de crear
  AuthRemoteDataSource({required this.apiClient});

  /// Inicia sesión y guarda el JWT en el dispositivo
  Future<String> login(String email, String password) async {
    try {
      final response = await apiClient.dio.post(
        '/auth/login',
        data: {
          'email': email,
          'password': password,
        },
      );

      final token = response.data['access_token'];
      final refreshToken = response.data['refresh_token'];

      await apiClient.storage.write(key: 'jwt_token', value: token);
      if (refreshToken != null) {
        await apiClient.storage
            .write(key: 'refresh_token', value: refreshToken);
      }

      return token;
    } on DioException catch (e) {
      String errorMessage = 'Credenciales incorrectas. Revisa tu correo y contraseña.';

      if (e.response != null) {
        final data = e.response?.data;
        if (data is Map && data.containsKey('detail') && data['detail'] != null) {
          errorMessage = data['detail'].toString();
        } else if (e.response?.statusCode == 401 || e.response?.statusCode == 400) {
          errorMessage = 'Credenciales incorrectas. Revisa tu correo y contraseña.';
        } else if (e.response?.statusCode != null) {
          errorMessage = 'Error del servidor (${e.response?.statusCode}). Intenta de nuevo.';
        }
      } else {
        // Sin respuesta del servidor → servidor caído o sin internet
        errorMessage = 'No se pudo conectar al servidor. Verifica tu conexión a internet.';
      }
      throw Exception(errorMessage);
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Error de conexión. Verifica tu internet.');
    }
  }

  /// Cierra sesión borrando los tokens
  Future<void> logout() async {
    try {
      // 1. Borrar el FCM token en el backend para dejar de recibir notificaciones de esta cuenta
      await apiClient.dio.put('/auth/fcm-token', data: {'fcm_token': ''});
    } catch (e) {
      debugPrint('No se pudo limpiar el FCM token en el servidor: $e');
    }
    // 2. Borrar las credenciales locales
    await apiClient.storage.delete(key: 'jwt_token');
    await apiClient.storage.delete(key: 'refresh_token');
  }

  /// Verifica si el usuario ya tiene una sesión activa al abrir la app
  Future<bool> hasValidToken() async {
    try {
      final token = await apiClient.storage.read(key: 'jwt_token');
      return token != null && token.isNotEmpty;
    } catch (e) {
      // Si el keystore está corrupto (dispositivo nuevo o reinstalación),
      // limpiamos todo el storage y tratamos como no autenticado
      debugPrint('⚠️ Error leyendo token (keystore corrupto): $e');
      await apiClient.storage.deleteAll();
      return false;
    }
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
      print('🚨 ERROR ${e.response?.statusCode} DE FASTAPI:');
      print('📦 Body completo: ${e.response?.data}');
      print(
          '📤 Datos enviados: fullName=$fullName, email=$email, phone=$phone, role=$role');

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
      throw Exception(
          'Error de conexión: Verifica que el servidor esté encendido.');
    }
  }

  Future<User> getUserProfile() async {
    try {
      // ⚠️ Asegúrate de que esta ruta tenga el prefijo correcto (ej. /auth/me o /users/me)
      final response = await apiClient.dio.get('/auth/me');

      debugPrint('==================================================');
      debugPrint('🚨 [DEBUG PROD] RESPUESTA CRUDA DE /auth/me:');
      debugPrint('${response.data}');
      debugPrint('==================================================');

      return User.fromJson(response.data);
    } on DioException catch (e) {
      // 1. Si el servidor respondió con un error (400, 422, 500)
      if (e.response != null) {
        debugPrint(
            '🛑 EL SERVIDOR RESPONDIÓ CON ERROR: ${e.response?.statusCode}');
        debugPrint('🛑 DETALLE DEL ERROR: ${e.response?.data}');
      }
      // 2. Si el servidor NUNCA respondió (Apagado, sin internet, error de ruta)
      else {
        debugPrint('🚨 EL SERVIDOR NO RESPONDIÓ (¿Está apagado uvicorn?)');
        debugPrint('🚨 TIPO DE ERROR DIO: ${e.type}');
        debugPrint('🚨 MENSAJE: ${e.message}');
      }
      throw Exception('Falló el registro HTTP');
    }
  }

  Future<String> uploadProfilePicture(String userId, XFile imageFile) async {
    try {
      // 1. Leemos el archivo como BYTES puros (Esto funciona perfecto en Web y Móvil)
      final bytes = await imageFile.readAsBytes();

      // 2. Empacamos los bytes para enviarlos a FastAPI
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          bytes,
          filename: imageFile.name, // XFile nos da el nombre seguro
        ),
      });

      final response = await apiClient.dio.post(
        '/auth/$userId/profile-picture',
        data: formData,
      );

      final nuevaUrl = response.data['profile_picture_url'];

      if (nuevaUrl == null) {
        // Esto te ayudará a debuggear si vuelve a fallar
        debugPrint("JSON recibido: ${response.data}");
        throw Exception("No se encontró 'profile_picture_url' en la respuesta");
      }

      return nuevaUrl.toString();
    } catch (e) {
      throw Exception('Error subiendo foto: $e');
    }
  }

  Future<void> updateLocation({
    required String userId,
    required double lat,
    required double lng,
    required String city,
  }) async {
    try {
      // Usamos el cliente de Dio para mandarle los datos al backend
      await apiClient.dio.put(
        '/auth/update-location/$userId', // 👈 Ajusta esta ruta según tu FastAPI
        data: {
          'latitude': lat,
          'longitude': lng,
          'city': city,
        },
      );
      debugPrint('🛰️ Ubicación enviada al servidor con éxito');
    } on DioException catch (e) {
      debugPrint(
          '🚨 Error en DataSource al actualizar ubicación: ${e.response?.data}');
      throw Exception('No se pudo guardar la ubicación en el servidor');
    }
  }

  Future<void> updateProfileData({
    required String userId,
    required String fullName,
    required String phone,
    String? bio,
    List<String>? categoryIds,
  }) async {
    try {
      await apiClient.dio.put(
        '/auth/users/$userId',
        data: {
          'full_name': fullName,
          'phone': phone,
          if (bio != null) 'bio': bio,
          if (categoryIds != null) 'category_ids': categoryIds,
        },
      );
    } catch (e) {
      throw Exception('Error actualizando perfil: $e');
    }
  }

  Future<void> updateFcmToken(String fcmToken) async {
    try {
      await apiClient.dio.put(
        '/auth/fcm-token',
        data: {'fcm_token': fcmToken},
      );
      debugPrint('📱 FCM Token actualizado en el servidor');
    } catch (e) {
      debugPrint('🚨 Error actualizando FCM Token: $e');
    }
  }

  /// Verifica el código de 6 dígitos enviado al correo
  /// Ahora también guarda los JWT tokens que el backend devuelve tras la verificación
  Future<void> verifyEmailCode(String email, String code) async {
    try {
      final response = await apiClient.dio.post(
        '/auth/verify-code',
        data: {
          'email': email,
          'code': code,
        },
      );

      // El backend ahora devuelve tokens JWT tras verificar exitosamente
      final token = response.data['access_token'];
      final refreshToken = response.data['refresh_token'];

      if (token != null) {
        await apiClient.storage.write(key: 'jwt_token', value: token);
      }
      if (refreshToken != null) {
        await apiClient.storage
            .write(key: 'refresh_token', value: refreshToken);
      }
    } on DioException catch (e) {
      String errorMessage = 'Error al verificar el código';
      if (e.response != null && e.response?.data != null) {
        if (e.response?.data['detail'] is String) {
          errorMessage = e.response?.data['detail'];
        }
      }
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('Error de conexión');
    }
  }

  /// Reenvía el código de verificación por correo
  Future<void> resendVerificationCode(String email) async {
    try {
      await apiClient.dio.post(
        '/auth/resend-code',
        data: {
          'email': email,
        },
      );
    } on DioException catch (e) {
      String errorMessage = 'Error al reenviar el código';
      if (e.response != null && e.response?.data != null) {
        if (e.response?.data['detail'] is String) {
          errorMessage = e.response?.data['detail'];
        }
      }
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('Error de conexión');
    }
  }

  /// Solicita un código de recuperación de contraseña
  Future<void> forgotPassword(String email) async {
    try {
      await apiClient.dio.post(
        '/auth/forgot-password',
        data: {'email': email},
      );
    } on DioException catch (e) {
      String errorMessage = 'Error al solicitar recuperación';
      if (e.response != null && e.response?.data != null) {
        if (e.response?.data['detail'] is String) {
          errorMessage = e.response?.data['detail'];
        }
      }
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('Error de conexión');
    }
  }

  /// Verifica que el código de recuperación sea correcto (sin cambiar la contraseña)
  Future<void> verifyResetCode(String email, String code) async {
    try {
      await apiClient.dio.post(
        '/auth/verify-reset-code',
        data: {'email': email, 'code': code},
      );
    } on DioException catch (e) {
      String errorMessage = 'Código incorrecto';
      if (e.response != null && e.response?.data != null) {
        if (e.response?.data['detail'] is String) {
          errorMessage = e.response?.data['detail'];
        }
      }
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('Error de conexión');
    }
  }

  /// Restablece la contraseña usando el código de recuperación
  Future<void> resetPassword(
      String email, String code, String newPassword) async {
    try {
      await apiClient.dio.post(
        '/auth/reset-password',
        data: {
          'email': email,
          'code': code,
          'new_password': newPassword,
        },
      );
    } on DioException catch (e) {
      String errorMessage = 'Error al restablecer la contraseña';
      if (e.response != null && e.response?.data != null) {
        if (e.response?.data['detail'] is String) {
          errorMessage = e.response?.data['detail'];
        }
      }
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('Error de conexión');
    }
  }
}
