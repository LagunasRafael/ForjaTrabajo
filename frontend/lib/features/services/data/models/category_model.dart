import '../../domain/entities/category_entity.dart';

class CategoryModel extends CategoryEntity {
  CategoryModel({
    required super.id,
    required super.name,
    required super.description,
    required super.isActive,
  });
  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      // 👇 Usamos ?.toString() para asegurar que los UUIDs no rompan la app
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      // 👇 Validación más estricta para booleanos
      isActive: json['is_active'] == true, 
    );
  }
}