enum JobStatus { open, matched, waiting_confirmation, completed, cancelled }

class ServiceEntity {
  final String id;
  final String title;
  final String? summary; // ✅ NUEVO
  final String description;
  final double basePrice;
  final String categoryId;
  final String clientId;
  final double? latitude; // ✅ NUEVO
  final double? longitude; // ✅ NUEVO
  final String? exactAddress; // ✅ NUEVO
  final List<String> imageUrls; // ✅ NUEVO
  final JobStatus status;
  final bool isActive;
  final DateTime createdAt;
  final String? authorName;
  final String? profilePictureUrl;
  final String? requestId;

  ServiceEntity({
    required this.id,
    required this.title,
    this.summary,
    required this.description,
    required this.basePrice,
    required this.categoryId,
    required this.clientId,
    this.latitude,
    this.longitude,
    this.exactAddress,
    this.imageUrls = const [],
    required this.status,
    required this.isActive,
    required this.createdAt,
    this.authorName,
    this.profilePictureUrl,
    this.requestId,
  });

  ServiceEntity copyWith({
    String? id,
    String? title,
    String? summary,
    String? description,
    double? basePrice,
    String? categoryId,
    String? clientId,
    double? latitude,
    double? longitude,
    String? exactAddress,
    List<String>? imageUrls,
    JobStatus? status,
    bool? isActive,
    DateTime? createdAt,
    String? authorName,
    String? profilePictureUrl,
    String? requestId,
  }) {
    return ServiceEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      summary: summary ?? this.summary,
      description: description ?? this.description,
      basePrice: basePrice ?? this.basePrice,
      categoryId: categoryId ?? this.categoryId,
      clientId: clientId ?? this.clientId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      exactAddress: exactAddress ?? this.exactAddress,
      imageUrls: imageUrls ?? this.imageUrls,
      status: status ?? this.status,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      authorName: authorName ?? this.authorName,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      requestId: requestId ?? this.requestId,
    );
  }
}