import 'service_entity.dart'; // Importamos para usar JobStatus

class JobEntity {
  final String id;
  final String requestId;
  final String providerId;
  final String clientId;
  final JobStatus status;
  final double finalPrice;
  final DateTime? startedAt;
  final DateTime? completedAt;

  JobEntity({
    required this.id,
    required this.requestId,
    required this.providerId,
    required this.clientId,
    required this.status,
    required this.finalPrice,
    this.startedAt,
    this.completedAt,
  });
}