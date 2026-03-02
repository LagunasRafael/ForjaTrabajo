import 'package:equatable/equatable.dart';

class ServiceRequestEntity extends Equatable {
  final String id;
  final String serviceId;
  final String workerId;
  final String description;
  final String status;
  final DateTime createdAt;
  final String? workerName;     
  final double? proposedPrice;  
  
  // 👇 Usamos el nombre alineado con tu schema y el resto de tu app
  final String? authorImageUrl;

  const ServiceRequestEntity({
    required this.id,
    required this.serviceId,
    required this.workerId,
    required this.description,
    required this.status,
    required this.createdAt,
    this.workerName,      
    this.proposedPrice,   
    this.authorImageUrl, // <--- Aquí
  });

  @override
  List<Object?> get props => [
    id, serviceId, workerId, description, status, createdAt, workerName, proposedPrice, authorImageUrl
  ];
}