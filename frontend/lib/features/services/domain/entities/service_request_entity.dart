import 'package:equatable/equatable.dart';

class ServiceRequestEntity extends Equatable {
  final String id;
  final String serviceId;
  final String workerId;
  final String description;
  final String status;
  final DateTime createdAt;

  // 👇 AGREGA ESTOS DOS CAMPOS
  final String? workerName;     
  final double? proposedPrice;  

  const ServiceRequestEntity({
    required this.id,
    required this.serviceId,
    required this.workerId,
    required this.description,
    required this.status,
    required this.createdAt,
    this.workerName,      // <--- Aquí
    this.proposedPrice,   // <--- Aquí
  });

  @override
  List<Object?> get props => [
    id, serviceId, workerId, description, status, createdAt, workerName, proposedPrice
  ];
}