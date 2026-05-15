class ReviewModel {
  final String id;
  final String jobId;
  final String reviewerId;
  final String revieweeId;
  final int rating;
  final String? comment;
  final DateTime createdAt;
  final String? reviewerName;
  final String? reviewerImageUrl;

  ReviewModel({
    required this.id,
    required this.jobId,
    required this.reviewerId,
    required this.revieweeId,
    required this.rating,
    this.comment,
    required this.createdAt,
    this.reviewerName,
    this.reviewerImageUrl,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: json['id'] ?? '',
      jobId: json['job_id'] ?? '',
      reviewerId: json['reviewer_id'] ?? '',
      revieweeId: json['reviewee_id'] ?? '',
      rating: json['rating'] ?? 5,
      comment: json['comment'],
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      reviewerName: json['reviewer_name'],
      reviewerImageUrl: json['reviewer_image_url'],
    );
  }
}
