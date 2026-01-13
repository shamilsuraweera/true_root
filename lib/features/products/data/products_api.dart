import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/api/api_config.dart';
import '../models/product.dart';

class ProductsApi {
  ProductsApi({String? baseUrl}) : baseUrl = baseUrl ?? ApiConfig.baseUrl;

  final String baseUrl;

  Future<List<Product>> fetchProducts() async {
    final uri = Uri.parse('$baseUrl/products');
    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Failed to load products');
    }
    final data = jsonDecode(response.body) as List<dynamic>;
    return data.map((item) => Product.fromApi(item as Map<String, dynamic>)).toList();
  }
}
