import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/category_entity.dart';
import '../models/category_model.dart';
import '../../../../core/network/api_client.dart';

final categoryRemoteDataSourceProvider = Provider((ref) {
  final apiClient = ApiClient();
  return CategoryRemoteDataSource(apiClient);
});

class CategoryRemoteDataSource {
  final ApiClient _apiClient;

  CategoryRemoteDataSource(this._apiClient);

  String get baseUrl => '${_apiClient.dio.options.baseUrl}/services/categories';

  Future<List<CategoryModel>> getCategories() async {
    final response = await http.get(Uri.parse(baseUrl));
    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((e) => CategoryModel.fromJson(e)).toList();
    } else {
      throw Exception('Error al cargar categorías');
    }
  }

  Future<void> createCategory(
      String name, String description, String token) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'name': name,
        'description': description, // 👈 Agregamos la descripción aquí
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Error al crear categoría: ${response.body}');
    }
  }

  Future<void> deleteCategory(String id, String token) async {
    final response = await http.delete(
      Uri.parse("$baseUrl/$id"),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('No se pudo eliminar la categoría');
    }
  }

  Future<List<CategoryModel>> getTopCategories() async {
    try {
      // Usamos la URL base pero apuntando al nuevo endpoint del backend
      final String topUrl =
          "${_apiClient.dio.options.baseUrl}/services/top-categories";

      final response = await http.get(Uri.parse(topUrl));

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        // Usamos CategoryModel.fromJson (que ya tienes definido arriba)
        return jsonList.map((e) => CategoryModel.fromJson(e)).toList();
      } else {
        throw Exception('Error al cargar las top categorías');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }
}
