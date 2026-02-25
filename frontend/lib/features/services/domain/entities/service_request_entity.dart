class ServiceRequestEntity {
  final String id;
  final String serviceId;
  final String workerId;
  final String description;
  final String status;
  final DateTime createdAt;

  ServiceRequestEntity({
    required this.id,
    required this.serviceId,
    required this.workerId,
    required this.description,
    required this.status,
    required this.createdAt,
  });
}