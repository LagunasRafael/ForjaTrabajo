import 'package:image_picker/image_picker.dart';
import 'package:forja_trabajo/features/auth/domain/repositories/auth_repository.dart';
import 'package:forja_trabajo/features/auth/domain/models/user_model.dart';
import 'package:forja_trabajo/features/auth/data/datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource dataSource;

  AuthRepositoryImpl({required this.dataSource});

  @override
  Future<String> login(String identifier, String password) =>
      dataSource.login(identifier, password);

  @override
  Future<void> logout() => dataSource.logout();

  @override
  Future<bool> hasValidToken() => dataSource.hasValidToken();

  @override
  Future<void> register({
    required String fullName,
    required String email,
    String? phone,
    required String password,
    required String role,
  }) =>
      dataSource.register(
        fullName: fullName,
        email: email,
        phone: phone,
        password: password,
        role: role,
      );

  @override
  Future<User> getUserProfile() => dataSource.getUserProfile();

  @override
  Future<String> uploadProfilePicture(String userId, XFile imageFile) =>
      dataSource.uploadProfilePicture(userId, imageFile);

  @override
  Future<void> updateLocation({
    required String userId,
    required double lat,
    required double lng,
    required String city,
  }) =>
      dataSource.updateLocation(userId: userId, lat: lat, lng: lng, city: city);

  @override
  Future<void> updateProfileData({
    required String userId,
    required String fullName,
    required String phone,
    String? bio,
    List<String>? categoryIds,
  }) =>
      dataSource.updateProfileData(
        userId: userId,
        fullName: fullName,
        phone: phone,
        bio: bio,
        categoryIds: categoryIds,
      );

  @override
  Future<void> updateFcmToken(String fcmToken) =>
      dataSource.updateFcmToken(fcmToken);

  @override
  Future<void> verifyEmailCode(String email, String code) =>
      dataSource.verifyEmailCode(email, code);

  @override
  Future<void> resendVerificationCode(String email) =>
      dataSource.resendVerificationCode(email);

  @override
  Future<void> forgotPassword(String email) =>
      dataSource.forgotPassword(email);

  @override
  Future<void> verifyResetCode(String email, String code) =>
      dataSource.verifyResetCode(email, code);

  @override
  Future<void> resetPassword(String email, String code, String newPassword) =>
      dataSource.resetPassword(email, code, newPassword);
}
