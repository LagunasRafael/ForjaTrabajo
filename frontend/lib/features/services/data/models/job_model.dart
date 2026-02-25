
import '../../domain/entities/job_entity.dart';
import '../../domain/entities/service_entity.dart'; // Para JobStatus

class JobModel extends JobEntity {
  JobModel({
    required super.id,
    required super.requestId,
    required super.providerId,
    required super.clientId,
    required super.status,
    required super.finalPrice,
    super.startedAt,
    super.completedAt,
  });

  factory JobModel.fromJson(Map<String, dynamic> json) {
    JobStatus statusFromString(String val) {
      return JobStatus.values.firstWhere(
        (e) => e.toString().split('.').last == val,
        orElse: () => JobStatus.matched,
      );
    }

    return JobModel(
      id: json['id'] ?? '',
      requestId: json['request_id'] ?? '',
      providerId: json['provider_id'] ?? '',
      clientId: json['client_id'] ?? '',
      status: statusFromString(json['status'] ?? 'matched'),
      finalPrice: (json['final_price'] as num?)?.toDouble() ?? 0.0,
      startedAt: json['started_at'] != null 
          ? DateTime.parse(json['started_at']) 
          : null,
      completedAt: json['completed_at'] != null 
          ? DateTime.parse(json['completed_at']) 
          : null,
    );
  }
}