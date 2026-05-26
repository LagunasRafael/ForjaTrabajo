import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

// 🛠️ Core e Infraestructura
import '../../../../core/network/api_client.dart';
import '../../../../core/network/fcm_service.dart';
import '../../data/datasources/auth_remote_data_source.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/models/user_model.dart';

// 🚀 Providers de Servicios (Para limpieza de caché en Logout)
import 'package:forja_trabajo/features/services/presentation/providers/job_management_provider.dart';
import 'package:forja_trabajo/features/services/presentation/providers/service_list_provider.dart';
import 'package:forja_trabajo/features/chat/presentation/providers/chat_list_provider.dart';
import 'package:forja_trabajo/features/chat/presentation/providers/chat_provider.dart';
import 'package:forja_trabajo/features/chat/presentation/providers/unread_count_provider.dart';
import 'package:forja_trabajo/features/notifications/presentation/providers/notification_provider.dart';
import 'package:forja_trabajo/features/payments/presentation/providers/wallet_status_provider.dart';

// 1. INSTANCIAS GLOBALES
final apiClientProvider = Provider((ref) => ApiClient());

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final dataSource = AuthRemoteDataSource(apiClient: apiClient);
  return AuthRepositoryImpl(dataSource: dataSource);
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

// 3. EL CONTROLADOR (NOTIFIER)
class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    Future.microtask(() => checkAuthStatus());
    return AuthState();
  }

  Future<void> checkAuthStatus() async {
    final dataSource = ref.read(authRepositoryProvider);
    final hasToken = await dataSource.hasValidToken();

    if (hasToken) {
      await fetchProfile();
      state = state.copyWith(status: 'authenticated');
      // 🚀 LAZY INITIALIZATION
      Future.delayed(const Duration(seconds: 2), () {
        _syncFcmToken();
      });
    } else {
      state = state.copyWith(status: 'unauthenticated');
    }
  }

  Future<void> loginUser(String identifier, String password) async {
    state = state.copyWith(status: 'loading', errorMessage: '');
    try {
      final dataSource = ref.read(authRepositoryProvider);
      final token = await dataSource.login(identifier, password);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token);

      await fetchProfile();

      state = state.copyWith(status: 'authenticated');
      // 🚀 FORZAR RECARGA DE CHATS: Al iniciar sesión limpiamos la caché vieja
      // para que el chatListProvider vuelva a hacer la petición con la nueva cuenta.
      ref.invalidate(chatListProvider);
      ref.invalidate(walletStatusProvider);

      // 🚀 LAZY INITIALIZATION
      Future.delayed(const Duration(seconds: 2), () {
        _syncFcmToken();
      });
    } catch (e) {
      state = state.copyWith(
          status: 'error',
          errorMessage: e.toString().replaceAll('Exception: ', ''));
    }
  }

  // 🚀 MÉTODO AÑADIDO: Para reenviar el código de verificación
  Future<void> resendEmail(String email) async {
    state = state.copyWith(status: 'loading', errorMessage: '');
    try {
      final dataSource = ref.read(authRepositoryProvider);
      await dataSource.resendVerificationCode(email);
      state = state.copyWith(status: 'email_resent', errorMessage: '');
    } catch (e) {
      state = state.copyWith(
          status: 'error',
          errorMessage: e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> logoutUser() async {
    try {
      ref.invalidate(workerJobsProvider);
      ref.invalidate(myRequestsProvider);
      ref.invalidate(serviceListProvider);
      ref.invalidate(chatListProvider);
      ref.invalidate(chatProvider);
      ref.invalidate(unreadCountProvider);
      ref.invalidate(notificationListProvider);
      ref.invalidate(walletStatusProvider);

      final prefs = await SharedPreferences.getInstance();
      final dataSource = ref.read(authRepositoryProvider);

      await dataSource.logout();
      await prefs.remove('token');
    } catch (e) {
      debugPrint("Error en logout: $e");
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('token');
    } finally {
      state =
          AuthState(status: 'unauthenticated', user: null, errorMessage: '');
    }
  }

  Future<void> registerUser({
    required String fullName,
    required String email,
    String? phone,
    required String password,
    required String role,
  }) async {
    state = state.copyWith(status: 'loading', errorMessage: '');
    try {
      final dataSource = ref.read(authRepositoryProvider);
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
          errorMessage: e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> verifyEmail(String email, String code) async {
    state = state.copyWith(status: 'loading', errorMessage: '');
    try {
      final dataSource = ref.read(authRepositoryProvider);
      await dataSource.verifyEmailCode(email, code);

      // Ahora tenemos tokens guardados → podemos cargar el perfil completo
      await fetchProfile();

      // 🚀 LAZY INITIALIZATION
      Future.delayed(const Duration(seconds: 3), () {
        _syncFcmToken();
      });

      state = state.copyWith(status: 'email_verified');
    } catch (e) {
      state = state.copyWith(status: 'error', errorMessage: e.toString());
    }
  }

  Future<void> fetchProfile() async {
    try {
      final dataSource = ref.read(authRepositoryProvider);
      final userData = await dataSource.getUserProfile();
      state = state.copyWith(user: userData);

      if (userData.city == null || userData.city!.isEmpty) {
        Future.delayed(const Duration(seconds: 5), () {
          autoUpdateLocation();
        });
      }
    } catch (e) {
      debugPrint('Error fetchProfile: $e');
    }
  }

  Future<void> autoUpdateLocation() async {
    if (state.user == null) return;
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(const Duration(seconds: 10));

      List<Placemark> placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude);
      String cityName = "Desconocido";
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        cityName = "${place.locality ?? ''}, ${place.administrativeArea ?? ''}";
      }
      final dataSource = ref.read(authRepositoryProvider);
      await dataSource.updateLocation(
          userId: state.user!.id,
          lat: position.latitude,
          lng: position.longitude,
          city: cityName);
      final updatedUser = state.user!.copyWith(
          latitude: position.latitude,
          longitude: position.longitude,
          city: cityName);
      state = state.copyWith(user: updatedUser);
    } catch (e) {
      debugPrint('🚨 Error GPS: $e');
    }
  }

  Future<void> updateProfilePicture(XFile imageFile) async {
    if (state.user == null) return;
    final dataSource = ref.read(authRepositoryProvider);
    try {
      final newPhotoUrl =
          await dataSource.uploadProfilePicture(state.user!.id, imageFile);
      final updatedUser = state.user!.copyWith(profilePictureUrl: newPhotoUrl);
      state = state.copyWith(user: updatedUser);
    } catch (e) {
      debugPrint("Error subiendo foto: $e");
    }
  }

  Future<void> updateUserInfo({
    required String newName,
    required String newPhone,
    String? bio,
    List<String>? categoryIds,
  }) async {
    if (state.user == null) return;
    final dataSource = ref.read(authRepositoryProvider);
    try {
      await dataSource.updateProfileData(
        userId: state.user!.id,
        fullName: newName,
        phone: newPhone,
        bio: bio,
        categoryIds: categoryIds,
      );
      await fetchProfile();
    } catch (e) {
      debugPrint("🚨 Error updateUserInfo: $e");
    }
  }

  Future<void> forgotPassword(String email) async {
    state = state.copyWith(status: 'loading', errorMessage: '');
    try {
      final dataSource = ref.read(authRepositoryProvider);
      await dataSource.forgotPassword(email);
      state = state.copyWith(status: 'reset_code_sent');
    } catch (e) {
      state = state.copyWith(
          status: 'error',
          errorMessage: e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> verifyResetCode(String email, String code) async {
    state = state.copyWith(status: 'loading', errorMessage: '');
    try {
      final dataSource = ref.read(authRepositoryProvider);
      await dataSource.verifyResetCode(email, code);
      state = state.copyWith(status: 'reset_code_verified');
    } catch (e) {
      state = state.copyWith(
          status: 'error',
          errorMessage: e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> resetPassword(
      String email, String code, String newPassword) async {
    state = state.copyWith(status: 'loading', errorMessage: '');
    try {
      final dataSource = ref.read(authRepositoryProvider);
      await dataSource.resetPassword(email, code, newPassword);
      state = state.copyWith(status: 'password_reset_success');
    } catch (e) {
      state = state.copyWith(
          status: 'error',
          errorMessage: e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> _syncFcmToken() async {
    try {
      final fcmService = FcmService();
      await fcmService.initNotifications();
      final String? fcmToken = await fcmService.getToken();
      debugPrint('📢 DEBUG SYNC: Token obtenido = ${fcmToken != null ? 'SI' : 'NO (NULL)'}');
      if (fcmToken != null) {
        debugPrint('📢 DEBUG SYNC: Enviando token al servidor...');
        final dataSource = ref.read(authRepositoryProvider);
        await dataSource.updateFcmToken(fcmToken);
        fcmService.listenToTokenChanges((newToken) {
          debugPrint('📢 DEBUG SYNC: Token refrescado, enviando nuevo...');
          dataSource.updateFcmToken(newToken);
        });
      }
    } catch (e) {
      debugPrint('❌ Error sincronizando FCM token: $e');
    }
  }
}

final authProvider =
    NotifierProvider<AuthNotifier, AuthState>(() => AuthNotifier());
