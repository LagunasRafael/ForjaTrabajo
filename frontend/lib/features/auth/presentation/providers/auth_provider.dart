import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Solo añadimos esto
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

// 3. EL NUEVO CONTROLADOR (Estándar Moderno de Riverpod)
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
      await fetchProfile();
      state = state.copyWith(status: 'authenticated');
    } else {
      state = state.copyWith(status: 'unauthenticated');
    }
  }

  Future<void> loginUser(String email, String password) async {
    state = state.copyWith(status: 'loading', errorMessage: '');
    try {
      final dataSource = ref.read(authDataSourceProvider);
      
      // ✅ Realizamos el login normal (esto ya guarda el token en SecureStorage)
      final token = await dataSource.login(email, password);
      
      // 🆕 ADICIÓN: Guardamos una copia en SharedPreferences solo para que 
      // el CategoryProvider lo encuentre fácil (esto no rompe nada de lo anterior)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token);

      state = state.copyWith(status: 'authenticated');
      await fetchProfile();
    } catch (e) {
      state = state.copyWith(
        status: 'error', 
        errorMessage: e.toString().replaceAll('Exception: ', '')
      );
    }
  }

  Future<void> logoutUser() async {
    final dataSource = ref.read(authDataSourceProvider);
    
    // 🆕 Limpiamos el token de SharedPreferences también
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');

    await dataSource.logout(); 
    
    state = AuthState(
      status: 'unauthenticated',
      user: null, 
      errorMessage: ''
    );
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

  /// Detecta la ubicación automáticamente y actualiza el perfil
  Future<void> autoUpdateLocation() async {
    if (state.user == null || state.user?.city != null) return;

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return; 

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return; 
      }
      
      if (permission == LocationPermission.deniedForever) return;

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high
      );

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude, 
        position.longitude
      );

      String cityName = "Desconocido";
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        cityName = "${place.locality}, ${place.administrativeArea}"; 
      }

      print('📍 Ubicación detectada automáticamente: $cityName');

      final updatedUser = User(
        id: state.user!.id,
        email: state.user!.email,
        fullName: state.user!.fullName,
        role: state.user!.role,
        phone: state.user!.phone,
        latitude: position.latitude,
        longitude: position.longitude,
        city: cityName, 
      );

      state = state.copyWith(user: updatedUser);

    } catch (e) {
      print('🚨 Error detectando ubicación automática: $e');
    }
  }

  Future<void> fetchProfile() async {
    try {
      final dataSource = ref.read(authDataSourceProvider);
      final userData = await dataSource.getUserProfile();
      state = state.copyWith(user: userData); 

      if (userData.city == null) {
        autoUpdateLocation();
      }
    } catch (e) {
      debugPrint('Error descargando perfil: $e');
    }
  }
}

// 4. EL PROVIDER FINAL
final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});