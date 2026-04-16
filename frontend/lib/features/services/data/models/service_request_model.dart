import '../../domain/entities/service_request_entity.dart';

class ServiceRequestModel extends ServiceRequestEntity {
  ServiceRequestModel({
    required super.id,
    required super.serviceId,
    required super.workerId,
    required super.description,
    required super.status,
    required super.createdAt,
    super.workerName,
    super.proposedPrice,
    super.authorImageUrl, // <--- Aquí
  });

  factory ServiceRequestModel.fromEntity(ServiceRequestEntity entity) {
    return ServiceRequestModel(
      id: entity.id,
      serviceId: entity.serviceId,
      workerId: entity.workerId,
      description: entity.description,
      status: entity.status,
      createdAt: entity.createdAt,
      workerName: entity.workerName,
      proposedPrice: entity.proposedPrice,
      authorImageUrl: entity.authorImageUrl, // <--- Aquí
    );
  }

  factory ServiceRequestModel.fromJson(Map<String, dynamic> json) {
    return ServiceRequestModel(
      id: json['id']?.toString() ?? '',
      serviceId: json['service_id']?.toString() ?? '',
      workerId: json['worker_id']?.toString() ?? '',
      description: json['description'] ?? '',
      status: json['status'] ?? 'pending',
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      workerName: json['worker_name']?.toString() ?? "Trabajador",
      proposedPrice: json['proposed_price'] != null 
          ? double.tryParse(json['proposed_price'].toString()) 
          : null,
      
      // 👇 Usamos la llave exacta de tu backend
      authorImageUrl: json['author_image_url']?.toString(), 
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'service_id': serviceId,
      'worker_id': workerId,
      'description': description,
      'status': status,
      'proposed_price': proposedPrice,
    };
  }
}