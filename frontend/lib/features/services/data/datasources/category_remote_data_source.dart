import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/category_model.dart';

final categoryRemoteDataSourceProvider = Provider((ref) => CategoryRemoteDataSource());

class CategoryRemoteDataSource {
  // Plural "services" para que no de 404
  final String baseUrl = "http://127.0.0.1:8000/services/categories"; 

  Future<List<CategoryModel>> getCategories() async {
    final response = await http.get(Uri.parse(baseUrl));
    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((e) => CategoryModel.fromJson(e)).toList();
    } else {
      throw Exception('Error al cargar categorías');
    }
  }

    Future<void> createCategory(String name, String description, String token) async {
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
}