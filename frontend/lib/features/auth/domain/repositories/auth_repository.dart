import 'package:image_picker/image_picker.dart';
import 'package:forja_trabajo/features/auth/domain/models/user_model.dart';

abstract class AuthRepository {
  Future<String> login(String identifier, String password);
  Future<void> logout();
  Future<bool> hasValidToken();
  Future<void> register({
    required String fullName,
    required String email,
    String? phone,
    required String password,
    required String role,
  });
  Future<User> getUserProfile();
  Future<String> uploadProfilePicture(String userId, XFile imageFile);
  Future<void> updateLocation({
    required String userId,
    required double lat,
    required double lng,
    required String city,
  });
  Future<void> updateProfileData({
    required String userId,
    required String fullName,
    required String phone,
    String? bio,
    List<String>? categoryIds,
  });
  Future<void> updateFcmToken(String fcmToken);
  Future<void> verifyEmailCode(String email, String code);
  Future<void> resendVerificationCode(String email);
  Future<void> forgotPassword(String email);
  Future<void> verifyResetCode(String email, String code);
  Future<void> resetPassword(String email, String code, String newPassword);
}
