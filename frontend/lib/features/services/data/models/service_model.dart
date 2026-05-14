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
    super.authorName,
    super.profilePictureUrl,
    super.requestId,
    super.workerName,
    super.workerImageUrl,
    super.alreadyReviewed,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    // 1. Helper para el Estatus
    JobStatus statusFromString(String val) {
      return JobStatus.values.firstWhere(
        (e) => e.name.toLowerCase() == val.toLowerCase(),
        orElse: () => JobStatus.open,
      );
    }

    // 2. Blindaje de lista de imágenes
    List<String> parseImages(dynamic urls) {
      if (urls == null) return [];
      if (urls is List) return urls.map((e) => e.toString()).toList();
      return [];
    }

    // 3. Conversión segura de coordenadas y precios
    double? parseDouble(dynamic value) {
      if (value == null) return null;
      return double.tryParse(value.toString());
    }

    return ServiceModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      summary: json['summary']?.toString(),
      description: json['description']?.toString() ?? '',
      basePrice: parseDouble(json['base_price']) ?? 0.0,
      categoryId: json['category_id']?.toString() ?? '',
      clientId: json['client_id']?.toString() ?? '',
      latitude: parseDouble(json['latitude']),
      longitude: parseDouble(json['longitude']),
      exactAddress: json['exact_address']?.toString(),
      imageUrls: parseImages(json['image_urls']),
      status: statusFromString(json['status']?.toString() ?? 'open'),
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now(),
      authorName: json['author_name']?.toString() ?? "Usuario Cliente",
      profilePictureUrl: json['author_image_url']?.toString(),
      requestId: json['request_id']?.toString(),
      workerName: json['worker_name']?.toString(),
      workerImageUrl: json['worker_image_url']?.toString(),
      alreadyReviewed: json['already_reviewed'] ?? false,
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
      // 'author_name' no se envía, el backend lo deduce del token
    };
  }

  // --- MÉTODOS DE CONVERSIÓN ---

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
      authorName: entity.authorName,
      profilePictureUrl: entity.profilePictureUrl,
      requestId: entity.requestId,
      workerName: entity.workerName,
      workerImageUrl: entity.workerImageUrl,
      alreadyReviewed: entity.alreadyReviewed,
    );
  }

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
      authorName: authorName,
      profilePictureUrl: profilePictureUrl,
      requestId: requestId,
      workerName: workerName,
      workerImageUrl: workerImageUrl,
      alreadyReviewed: alreadyReviewed,
    );
  }
}