import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../data/datasources/profile_remote_data_source.dart';
import '../../data/datasources/verification_remote_data_source.dart';
import '../../domain/models/public_profile_model.dart';
import '../../domain/models/review_model.dart';


final apiClientProvider = Provider((ref) => ApiClient());

final profileRemoteDataSourceProvider = Provider((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ProfileRemoteDataSource(apiClient: apiClient);
});

// Provider para el Perfil Público
final publicProfileProvider = FutureProvider.family<PublicProfileModel, String>((ref, userId) async {
  final dataSource = ref.watch(profileRemoteDataSourceProvider);
  return await dataSource.getUserProfile(userId);
});

// Provider para las Reseñas
final userReviewsProvider = FutureProvider.family<List<ReviewModel>, String>((ref, userId) async {
  final dataSource = ref.watch(profileRemoteDataSourceProvider);
  return await dataSource.getUserReviews(userId);
});

final verificationStatusProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final ds = ref.watch(verificationDataSourceProvider);
  return await ds.getVerificationStatus();
});
