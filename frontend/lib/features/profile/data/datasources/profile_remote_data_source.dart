import '../../../../core/network/api_client.dart';
import '../../domain/models/public_profile_model.dart';
import '../../domain/models/review_model.dart';

class ProfileRemoteDataSource {
  final ApiClient apiClient;

  ProfileRemoteDataSource({required this.apiClient});

  Future<PublicProfileModel> getUserProfile(String userId) async {
    try {
      final response = await apiClient.dio.get('/auth/users/$userId/profile');
      return PublicProfileModel.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to load user profile: $e');
    }
  }

  Future<List<ReviewModel>> getUserReviews(String userId) async {
    try {
      final response = await apiClient.dio.get('/auth/users/$userId/reviews');
      return (response.data as List)
          .map((json) => ReviewModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to load user reviews: $e');
    }
  }

  Future<ReviewModel> leaveReview(String jobId, int rating, String? comment) async {
    try {
      final response = await apiClient.dio.post(
        '/services/jobs/$jobId/review',
        data: {
          'rating': rating,
          if (comment != null && comment.isNotEmpty) 'comment': comment,
        },
      );
      return ReviewModel.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to post review: $e');
    }
  }
}
