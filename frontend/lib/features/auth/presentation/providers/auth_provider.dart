import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    // Al arrancar, mandamos a verificar si hay token guardado
    // Usamos microtask para que lo haga justito después de arrancar
    Future.microtask(() => checkAuthStatus());
    
    // Retornamos el estado inicial por defecto
    return AuthState();
  }

  Future<void> checkAuthStatus() async {
    // En el nuevo Notifier, tenemos acceso directo a "ref" en cualquier momento
    final dataSource = ref.read(authDataSourceProvider);
    final hasToken = await dataSource.hasValidToken();
    
    if (hasToken) {
      // Descargamos el perfil del usuario
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
      await dataSource.login(email, password);
      state = state.copyWith(status: 'authenticated');
      // Descargamos el perfil del usuario
      await fetchProfile();
    } catch (e) {
      state = state.copyWith(
        status: 'error', 
        // Limpiamos el texto del error para que se vea bonito en pantalla
        errorMessage: e.toString().replaceAll('Exception: ', '')
      );
    }
  }

  Future<void> logoutUser() async {
    final dataSource = ref.read(authDataSourceProvider);
    await dataSource.logout();
    state = state.copyWith(status: 'unauthenticated');
  }

  Future<void> registerUser({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    required String role,

  }) async {
    // 1. Ponemos la app en modo carga
    state = state.copyWith(status: 'loading', errorMessage: '');

    try {
      final dataSource = ref.read(authDataSourceProvider);
      // 2. Disparamos la petición a FastAPI
      await dataSource.register(
        fullName: fullName,
        email: email,
        phone: phone,
        password: password,
        role: role,
        
      );
      
      // 3. ¡Éxito! Cambiamos el estado para que la UI sepa que terminamos
      state = state.copyWith(status: 'registered');
      
    } catch (e) {
      // 4. ¡Error! Le mandamos el mensaje rojo a la UI
      state = state.copyWith(
        status: 'error', 
        errorMessage: e.toString().replaceAll('Exception: ', '')
      );
    }
  }

  /// Detecta la ubicación automáticamente y actualiza el perfil
  Future<void> autoUpdateLocation() async {
    // 1. Verificamos si ya tenemos los datos en el estado para no gastar batería
    if (state.user == null || state.user?.city != null) return;

    try {
      // 2. Revisamos permisos
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return; // El GPS está apagado

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return; // Nos dijo que no
      }
      
      if (permission == LocationPermission.deniedForever) return;

      // 3. ¡Obtenemos las coordenadas exactas!
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high
      );

      // 4. Traducimos las coordenadas a Ciudad, Estado (Geocoding)
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude, 
        position.longitude
      );

      String cityName = "Desconocido";
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        // locality suele ser el municipio/ciudad, administrativeArea el estado
        cityName = "${place.locality}, ${place.administrativeArea}"; 
      }

      print('📍 Ubicación detectada automáticamente: $cityName');

      // 5. TODO: Aquí llamaremos a FastAPI (ej. dataSource.updateLocation(...))
      // await dataSource.updateLocation(position.latitude, position.longitude, cityName);

      // 6. Actualizamos la pantalla al instante simulando que ya se guardó
      final updatedUser = User(
        id: state.user!.id,
        email: state.user!.email,
        fullName: state.user!.fullName,
        role: state.user!.role,
        phone: state.user!.phone,
        latitude: position.latitude,
        longitude: position.longitude,
        city: cityName, // ¡Inyectamos la ciudad real!
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
      // Guardamos al usuario en la memoria de la pantalla
      state = state.copyWith(user: userData); 

      // 🚀 ¡NUEVO! Disparamos la detección automática si no tiene ciudad
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