class WorkEvidenceEntity {
  final String id;
  final String serviceId;
  final String workerId;
  final String imageUrl;
  final String? description;
  final DateTime createdAt;

  WorkEvidenceEntity({
    required this.id,
    required this.serviceId,
    required this.workerId,
    required this.imageUrl,
    this.description,
    required this.createdAt,
  });
}
