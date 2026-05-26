import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/api_client_provider.dart';
import '../../data/datasources/profile_remote_data_source.dart';
import '../../data/datasources/verification_remote_data_source.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../data/repositories/profile_repository_impl.dart';
import '../../domain/models/public_profile_model.dart';
import '../../domain/models/review_model.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ProfileRepositoryImpl(
    profileDataSource: ProfileRemoteDataSource(apiClient: apiClient),
    verificationDataSource: VerificationRemoteDataSource(apiClient: apiClient),
  );
});

final publicProfileProvider = FutureProvider.family<PublicProfileModel, String>((ref, userId) async {
  final repo = ref.watch(profileRepositoryProvider);
  return await repo.getUserProfile(userId);
});

final userReviewsProvider = FutureProvider.family<List<ReviewModel>, String>((ref, userId) async {
  final repo = ref.watch(profileRepositoryProvider);
  return await repo.getUserReviews(userId);
});

final verificationStatusProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final repo = ref.watch(profileRepositoryProvider);
  return await repo.getVerificationStatus();
});
