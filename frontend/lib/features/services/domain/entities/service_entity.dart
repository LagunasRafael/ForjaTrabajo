enum JobStatus { open, matched, completed, cancelled }

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
  });
}