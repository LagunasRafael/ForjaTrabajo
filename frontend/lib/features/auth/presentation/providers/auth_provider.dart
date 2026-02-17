import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/auth_remote_data_source.dart';
import '../../../../core/network/api_client.dart';

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

  AuthState({this.status = 'initial', this.errorMessage = ''});

  AuthState copyWith({String? status, String? errorMessage}) {
    return AuthState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
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
}

// 4. EL PROVIDER FINAL
final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});