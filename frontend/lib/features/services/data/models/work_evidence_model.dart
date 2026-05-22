import '../../domain/entities/work_evidence_entity.dart';

class WorkEvidenceModel extends WorkEvidenceEntity {
  WorkEvidenceModel({
    required super.id,
    required super.serviceId,
    required super.workerId,
    required super.imageUrl,
    super.description,
    required super.createdAt,
  });

  factory WorkEvidenceModel.fromJson(Map<String, dynamic> json) {
    return WorkEvidenceModel(
      id: json['id']?.toString() ?? '',
      serviceId: json['service_id']?.toString() ?? '',
      workerId: json['worker_id']?.toString() ?? '',
      imageUrl: json['image_url']?.toString() ?? '',
      description: json['description']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now(),
    );
  }

  WorkEvidenceEntity toEntity() {
    return WorkEvidenceEntity(
      id: id,
      serviceId: serviceId,
      workerId: workerId,
      imageUrl: imageUrl,
      description: description,
      createdAt: createdAt,
    );
  }
}
