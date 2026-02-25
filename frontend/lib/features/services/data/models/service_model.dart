import '../../domain/entities/service_entity.dart';

class ServiceModel extends ServiceEntity {
  ServiceModel({
    required super.id,
    required super.title,
    super.summary,
    required super.description,
    required super.basePrice,
    required super.categoryId,
    required super.clientId,
    super.latitude,
    super.longitude,
    super.exactAddress,
    super.imageUrls,
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

    // 🛡️ Blindaje de lista de imágenes
    List<String> parseImages(dynamic urls) {
      if (urls == null) return [];
      if (urls is List) {
        return urls.map((e) => e.toString()).toList();
      }
      return [];
    }

    double parsePrice(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    return ServiceModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      summary: json['summary']?.toString(), // ✅ NUEVO
      description: json['description']?.toString() ?? '',
      basePrice: double.tryParse(json['base_price']?.toString() ?? '0') ?? 0.0,
      categoryId: json['category_id']?.toString() ?? '',
      clientId: json['client_id']?.toString() ?? '',
      latitude: json['latitude'] != null ? double.tryParse(json['latitude'].toString()) : null, // ✅ NUEVO
      longitude: json['longitude'] != null ? double.tryParse(json['longitude'].toString()) : null, // ✅ NUEVO
      exactAddress: json['exact_address']?.toString(), // ✅ NUEVO
      imageUrls: parseImages(json['image_urls'] ?? []), // ✅ NUEVO
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
      'summary': summary,
      'description': description,
      'base_price': basePrice,
      'category_id': categoryId,
      'latitude': latitude,
      'longitude': longitude,
      'exact_address': exactAddress,
      'image_urls': imageUrls,
    };
  }
}