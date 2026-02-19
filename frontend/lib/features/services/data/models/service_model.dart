import '../../domain/entities/service_entity.dart';

class ServiceModel extends ServiceEntity {
  ServiceModel({
    required super.id,
    required super.title,
    required super.description,
    required super.basePrice,
    required super.categoryId,
    required super.clientId,
    required super.status,
    required super.isActive,
    required super.createdAt,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    JobStatus statusFromString(String val) {
      return JobStatus.values.firstWhere(
        (e) => e.name.toLowerCase() == val.toLowerCase(),
        orElse: () => JobStatus.open,
      );
    }

    // Manejo robusto para que "10000.00" no rompa la app
    double parsePrice(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    return ServiceModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      basePrice: parsePrice(json['base_price']),
      categoryId: json['category_id']?.toString() ?? '',
      clientId: json['client_id']?.toString() ?? '',
      status: statusFromString(json['status']?.toString() ?? 'open'),
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'].toString()) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'base_price': basePrice,
      'category_id': categoryId,
    };
  }
}