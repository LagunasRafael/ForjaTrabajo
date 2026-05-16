class JobSummaryModel {
  final String id;
  final String title;
  final String status;
  final double basePrice;
  final double? finalPrice;
  final DateTime? completedAt;
  final String? otherPartyName;
  final String? otherPartyImageUrl;
  final String roleInJob;

  JobSummaryModel({
    required this.id,
    required this.title,
    required this.status,
    this.basePrice = 0.0,
    this.finalPrice,
    this.completedAt,
    this.otherPartyName,
    this.otherPartyImageUrl,
    this.roleInJob = 'client',
  });

  factory JobSummaryModel.fromJson(Map<String, dynamic> json) {
    return JobSummaryModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      status: json['status'] ?? 'completed',
      basePrice: (json['base_price'] ?? 0.0).toDouble(),
      finalPrice: json['final_price']?.toDouble(),
      completedAt: json['completed_at'] != null
          ? DateTime.tryParse(json['completed_at'])
          : null,
      otherPartyName: json['other_party_name'],
      otherPartyImageUrl: json['other_party_image_url'],
      roleInJob: json['role_in_job'] ?? 'client',
    );
  }
}

class PublicProfileModel {
  final String id;
  final String fullName;
  final String? profilePictureUrl;
  final String role;
  final DateTime createdAt;
  final double averageRating;
  final int totalReviews;
  final bool isIdentityVerified;
  final List<JobSummaryModel> completedJobs;

  PublicProfileModel({
    required this.id,
    required this.fullName,
    this.profilePictureUrl,
    required this.role,
    required this.createdAt,
    this.averageRating = 0.0,
    this.totalReviews = 0,
    this.isIdentityVerified = false,
    this.completedJobs = const [],
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
      isIdentityVerified: json['is_identity_verified'] ?? false,
      completedJobs: (json['completed_jobs'] as List<dynamic>?)
          ?.map((j) => JobSummaryModel.fromJson(j as Map<String, dynamic>))
          .toList() ?? [],
    );
  }
}
