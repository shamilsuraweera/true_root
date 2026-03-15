import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/api/api_config.dart';
import '../models/product.dart';

class ProductsApi {
  ProductsApi({String? baseUrl, this.authToken})
    : baseUrl = baseUrl ?? ApiConfig.baseUrl;

  final String baseUrl;
  final String? authToken;

  Map<String, String> _headers({bool json = true}) {
    final headers = <String, String>{};
    if (json) {
      headers['Content-Type'] = 'application/json';
    }
    if (authToken != null && authToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $authToken';
    }
    return headers;
  }

  Future<List<Product>> fetchProducts() async {
    final uri = Uri.parse('$baseUrl/products');
    final response = await http.get(uri, headers: _headers(json: false));
    if (response.statusCode != 200) {
      throw Exception('Failed to load products');
    }
    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((item) => Product.fromApi(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<Product>> fetchProductsByOwner(String ownerId) async {
    final uri = Uri.parse('$baseUrl/products/owners/$ownerId');
    final response = await http.get(uri, headers: _headers(json: false));
    if (response.statusCode != 200) {
      throw Exception('Failed to load owner products');
    }
    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((item) => Product.fromApi(item as Map<String, dynamic>))
        .toList();
  }

  Future<Product> createProduct(Map<String, dynamic> payload) async {
    final uri = Uri.parse('$baseUrl/products');
    final response = await http.post(
      uri,
      headers: _headers(),
      body: jsonEncode(payload),
    );
    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Failed to create product');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return Product.fromApi(data);
  }

  Future<Product> updateProduct(int id, Map<String, dynamic> payload) async {
    final uri = Uri.parse('$baseUrl/products/$id');
    final response = await http.patch(
      uri,
      headers: _headers(),
      body: jsonEncode(payload),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update product');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return Product.fromApi(data);
  }

  Future<void> deleteProduct(int id) async {
    final uri = Uri.parse('$baseUrl/products/$id');
    final response = await http.delete(uri, headers: _headers(json: false));
    if (response.statusCode != 200) {
      throw Exception('Failed to delete product');
    }
  }
}
