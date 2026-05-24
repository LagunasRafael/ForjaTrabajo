import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:io' show Platform;
import 'package:forja_trabajo/core/network/notification_service.dart';
import 'package:forja_trabajo/core/utils/api_config.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  late Dio dio;
  final FlutterSecureStorage storage;

  // 🌐 DIRECCIÓN IP DE TU PC PARA PROBAR EN CELULAR FÍSICO (Ej. Android/iOS)
  // Reemplaza si cambia tu IP local

  //static final String _baseUrl = 'https://forja-api-rw0r.onrender.com';
  //static String get baseUrl => _baseUrl;
  static const String _baseUrl = "http://10.0.2.2:8000";


  factory ApiClient() => _instance;

  ApiClient._internal() : storage = const FlutterSecureStorage() {
    dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );
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
            // Evitar bucle infinito si la petición de refresh falla
            if (e.requestOptions.extra['isRetry'] == true) {
              return handler.next(e);
            }

            // 🛡️ GUARDIA 1: Si la petición original no envió Token, ignoramos la redirección
            final hasAuthHeader = e.requestOptions.headers.containsKey('Authorization');
            if (!hasAuthHeader) {
              return handler.next(e);
            }

            final refreshToken = await storage.read(key: 'refresh_token');

            if (refreshToken != null && refreshToken.isNotEmpty) {
              try {
                // Creamos un Dio nuevo SIN interceptores para evitar bucles
                final retryDio = Dio(BaseOptions(baseUrl: dio.options.baseUrl));

                final refreshResponse = await retryDio.post(
                  '/auth/refresh',
                  data: {'refresh_token': refreshToken},
                );

                if (refreshResponse.statusCode == 200) {
                  final newAccessToken = refreshResponse.data['access_token'];
                  final newRefreshToken = refreshResponse.data['refresh_token'];

                  // Guardamos los nuevos tokens
                  await storage.write(key: 'jwt_token', value: newAccessToken);
                  if (newRefreshToken != null) {
                    await storage.write(
                        key: 'refresh_token', value: newRefreshToken);
                  }

                  // Actualizamos el header de la petición fallida
                  e.requestOptions.headers['Authorization'] =
                      'Bearer $newAccessToken';
                  e.requestOptions.extra['isRetry'] =
                      true; // Marcamos como reintento

                  // Reintentamos la petición original instanciando una nueva
                  final retryResponse = await dio.fetch(e.requestOptions);
                  return handler.resolve(retryResponse);
                }
              } catch (refreshException) {
                print('🚨 Error al refrescar token: $refreshException');
              }
            }

            // 🛡️ GUARDIA 2: Si el usuario cerró sesión manualmente, el jwt_token ya será nulo.
            // En ese caso, evitamos limpiar la pantalla de Login actual de forma redundante.
            final currentToken = await storage.read(key: 'jwt_token');
            if (currentToken == null) {
              return handler.next(e);
            }

            // Si no hay refresh_token o el refresco falló: cerramos sesión
            await storage.delete(key: 'jwt_token');
            await storage.delete(key: 'refresh_token');

            print('🚨 Sesión totalmente expirada. Redirigiendo a login...');
            navigatorKey.currentState?.pushNamedAndRemoveUntil('/login', (route) => false);
          }
            return handler.next(e);
        },
      ),
    );
  }

  Future<Map<String, dynamic>> reportUser({
    required String reportedUserId,
    String? reportedServiceId,
    required String reason,
    String? description,
  }) async {
    final response = await dio.post(
      '/services/report',
      data: {
        'reported_user_id': reportedUserId,
        if (reportedServiceId != null) 'reported_service_id': reportedServiceId,
        'reason': reason,
        if (description != null) 'description': description,
      },
    );
    return response.data;
  }
}
