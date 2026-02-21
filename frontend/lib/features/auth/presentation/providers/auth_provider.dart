import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart'; 
import '../../data/datasources/auth_remote_data_source.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/models/user_model.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

// 1. INSTANCIAS GLOBALES
final apiClientProvider = Provider((ref) => ApiClient());

final authDataSourceProvider = Provider((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AuthRemoteDataSource(apiClient: apiClient);
});

// 2. LA CLASE DE ESTADO
class AuthState {
  final String status;
  final String errorMessage;
  final User? user;

  AuthState({this.status = 'initial', this.errorMessage = '', this.user});

  AuthState copyWith({String? status, String? errorMessage, User? user}) {
    return AuthState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      user: user ?? this.user,
    );
  }
}

// 3. EL NUEVO CONTROLADOR
class AuthNotifier extends Notifier<AuthState> {
  
  @override
  AuthState build() {
    Future.microtask(() => checkAuthStatus());
    return AuthState();
  }

  Future<void> checkAuthStatus() async {
    final dataSource = ref.read(authDataSourceProvider);
    final hasToken = await dataSource.hasValidToken();
    
    if (hasToken) {
      await fetchProfile(); // Descarga el perfil al abrir la app
      state = state.copyWith(status: 'authenticated');
    } else {
      state = state.copyWith(status: 'unauthenticated');
    }
  }

  Future<void> loginUser(String email, String password) async {
    state = state.copyWith(status: 'loading', errorMessage: '');
    try {
      final dataSource = ref.read(authDataSourceProvider);
      final token = await dataSource.login(email, password);
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token);

      state = state.copyWith(status: 'authenticated');
      await fetchProfile(); // 👇 Descarga el perfil al iniciar sesión (AQUÍ OBTIENES EL NOMBRE REAL)
    } catch (e) {
      state = state.copyWith(
        status: 'error', 
        errorMessage: e.toString().replaceAll('Exception: ', '')
      );
    }
  }

  Future<void> logoutUser() async {
    final dataSource = ref.read(authDataSourceProvider);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await dataSource.logout(); 
    
    state = AuthState(status: 'unauthenticated', user: null, errorMessage: '');
  }

  Future<void> registerUser({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    required String role,
  }) async {
    state = state.copyWith(status: 'loading', errorMessage: '');
    try {
      final dataSource = ref.read(authDataSourceProvider);
      await dataSource.register(
        fullName: fullName,
        email: email,
        phone: phone,
        password: password,
        role: role,
      );
      state = state.copyWith(status: 'registered');
    } catch (e) {
      state = state.copyWith(
        status: 'error', 
        errorMessage: e.toString().replaceAll('Exception: ', '')
      );
    }
  }

  // 👇 FUNCIÓN ARREGLADA: Descarga el perfil real del usuario
  Future<void> fetchProfile() async {
    try {
      final dataSource = ref.read(authDataSourceProvider);
      final userData = await dataSource.getUserProfile();
      
      // Actualizamos el estado con el usuario real de FastAPI
      state = state.copyWith(user: userData); 

      // Si no tiene ciudad guardada, intentamos buscarla
      if (userData.city == null || userData.city!.isEmpty) {
        autoUpdateLocation();
      }
    } catch (e) {
      debugPrint('Error descargando perfil: $e');
    }
  }

  // 👇 FUNCIÓN ARREGLADA: Ya no crashea si el GPS devuelve nulo
  Future<void> autoUpdateLocation() async {
    if (state.user == null) return;

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('🚨 GPS apagado');
        return; 
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return; 
      }
      
      if (permission == LocationPermission.deniedForever) return;

      // Usamos getCurrentPosition con un timeout para que no se quede colgado
      Position? position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(const Duration(seconds: 10), onTimeout: () => throw Exception('Timeout GPS'));

      // ✅ EL BLINDAJE CONTRA EL ERROR NULL VALUE
      // ignore: unnecessary_null_comparison
      if (position == null) {
         debugPrint('🚨 Geolocator devolvió null');
         return;
      }

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude, 
        position.longitude
      );

      String cityName = "Desconocido";
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        // Quitamos nulos de la dirección
        final locality = place.locality ?? '';
        final area = place.administrativeArea ?? '';
        if (locality.isNotEmpty || area.isNotEmpty) {
           cityName = "$locality, $area".trim().replaceAll(RegExp(r'^,|,$'), '');
        }
      }

      print('📍 Ubicación detectada: $cityName');

      final updatedUser = User(
        id: state.user!.id,
        email: state.user!.email,
        fullName: state.user!.fullName, // ✅ MANTIENE EL NOMBRE REAL
        role: state.user!.role,
        phone: state.user!.phone,
        latitude: position.latitude,
        longitude: position.longitude,
        city: cityName, 
      );

      state = state.copyWith(user: updatedUser);

    } catch (e) {
      print('🚨 Error silencioso detectando ubicación: $e');
    }
  }
}

// 4. EL PROVIDER FINAL
final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});