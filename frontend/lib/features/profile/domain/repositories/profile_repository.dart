import 'dart:io';
import 'package:forja_trabajo/features/profile/domain/models/public_profile_model.dart';
import 'package:forja_trabajo/features/profile/domain/models/review_model.dart';

abstract class ProfileRepository {
  Future<PublicProfileModel> getUserProfile(String userId);
  Future<List<ReviewModel>> getUserReviews(String userId);
  Future<ReviewModel> leaveReview(String jobId, int rating, String? comment);
  Future<Map<String, dynamic>> uploadVerification({
    required File ineFront,
    required File ineBack,
    required File selfie,
  });
  Future<Map<String, dynamic>> getVerificationStatus();
}
