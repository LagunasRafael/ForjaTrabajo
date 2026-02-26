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
    // 👇 1. Agregamos el nuevo campo al constructor
    super.authorName,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    JobStatus statusFromString(String val) {
      return JobStatus.values.firstWhere(
        (e) => e.name.toLowerCase() == val.toLowerCase(),
        orElse: () => JobStatus.open,
      );
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
      summary: json['summary']?.toString(),
      description: json['description']?.toString() ?? '',
      basePrice: parsePrice(json['base_price']),
      categoryId: json['category_id']?.toString() ?? '',
      clientId: json['client_id']?.toString() ?? '',
      latitude: json['latitude'] != null ? double.tryParse(json['latitude'].toString()) : null,
      longitude: json['longitude'] != null ? double.tryParse(json['longitude'].toString()) : null,
      exactAddress: json['exact_address']?.toString(),
      imageUrls: List<String>.from(json['image_urls'] ?? []),
      status: statusFromString(json['status']?.toString() ?? 'open'),
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'].toString()) 
          : DateTime.now(),
      
      // 👇 2. Leemos el dato que manda el Backend (o ponemos default)
      authorName: json['author_name']?.toString() ?? "Usuario Cliente",
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
      // No enviamos author_name al backend porque el backend ya sabe quién eres por el token
    };
  }

  // 👇 3. Aseguramos que el nombre pase de Entidad a Modelo
  factory ServiceModel.fromEntity(ServiceEntity entity) {
    return ServiceModel(
      id: entity.id,
      title: entity.title,
      summary: entity.summary,
      description: entity.description,
      basePrice: entity.basePrice,
      categoryId: entity.categoryId,
      clientId: entity.clientId,
      exactAddress: entity.exactAddress,
      latitude: entity.latitude,
      longitude: entity.longitude,
      imageUrls: entity.imageUrls,
      status: entity.status,
      isActive: entity.isActive,
      createdAt: entity.createdAt,
      authorName: entity.authorName, // <--- Aquí
    );
  }

  // 👇 4. Aseguramos que el nombre pase de Modelo a Entidad (para la UI)
  ServiceEntity toEntity() {
    return ServiceEntity(
      id: id,
      title: title,
      summary: summary,
      description: description,
      basePrice: basePrice,
      categoryId: categoryId,
      clientId: clientId,
      exactAddress: exactAddress,
      latitude: latitude,
      longitude: longitude,
      imageUrls: imageUrls,
      status: status,
      isActive: isActive,
      createdAt: createdAt,
      authorName: authorName, // <--- Y aquí
    );
  }
}