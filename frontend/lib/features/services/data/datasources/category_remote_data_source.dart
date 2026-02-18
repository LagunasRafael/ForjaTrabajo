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
}