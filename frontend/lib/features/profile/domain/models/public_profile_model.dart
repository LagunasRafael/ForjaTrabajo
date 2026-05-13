class PublicProfileModel {
  final String id;
  final String fullName;
  final String? profilePictureUrl;
  final String role;
  final DateTime createdAt;
  final double averageRating;
  final int totalReviews;

  PublicProfileModel({
    required this.id,
    required this.fullName,
    this.profilePictureUrl,
    required this.role,
    required this.createdAt,
    this.averageRating = 0.0,
    this.totalReviews = 0,
  });

  factory PublicProfileModel.fromJson(Map<String, dynamic> json) {
    return PublicProfileModel(
      id: json['id'] ?? '',
      fullName: json['full_name'] ?? 'Usuario Anónimo',
      profilePictureUrl: json['profile_picture_url'],
      role: json['role'] ?? 'user',
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      averageRating: (json['average_rating'] ?? 0.0).toDouble(),
      totalReviews: json['total_reviews'] ?? 0,
    );
  }
}
