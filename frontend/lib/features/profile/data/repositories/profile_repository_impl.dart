import 'dart:io';
import 'package:forja_trabajo/features/profile/domain/repositories/profile_repository.dart';
import 'package:forja_trabajo/features/profile/domain/models/public_profile_model.dart';
import 'package:forja_trabajo/features/profile/domain/models/review_model.dart';
import 'package:forja_trabajo/features/profile/data/datasources/profile_remote_data_source.dart';
import 'package:forja_trabajo/features/profile/data/datasources/verification_remote_data_source.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource profileDataSource;
  final VerificationRemoteDataSource verificationDataSource;

  ProfileRepositoryImpl({
    required this.profileDataSource,
    required this.verificationDataSource,
  });

  @override
  Future<PublicProfileModel> getUserProfile(String userId) =>
      profileDataSource.getUserProfile(userId);

  @override
  Future<List<ReviewModel>> getUserReviews(String userId) =>
      profileDataSource.getUserReviews(userId);

  @override
  Future<ReviewModel> leaveReview(String jobId, int rating, String? comment) =>
      profileDataSource.leaveReview(jobId, rating, comment);

  @override
  Future<Map<String, dynamic>> uploadVerification({
    required File ineFront,
    required File ineBack,
    required File selfie,
  }) =>
      verificationDataSource.uploadVerification(
        ineFront: ineFront,
        ineBack: ineBack,
        selfie: selfie,
      );

  @override
  Future<Map<String, dynamic>> getVerificationStatus() =>
      verificationDataSource.getVerificationStatus();
}
