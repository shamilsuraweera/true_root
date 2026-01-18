import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/api/api_config.dart';
import '../models/user.dart';

class UsersApi {
  UsersApi({String? baseUrl, this.authToken}) : baseUrl = baseUrl ?? ApiConfig.baseUrl;

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

  Future<List<AppUser>> fetchUsers() async {
    final uri = Uri.parse('$baseUrl/users');
    final response = await http.get(uri, headers: _headers(json: false));
    if (response.statusCode != 200) {
      throw Exception('Failed to load users');
    }
    final data = jsonDecode(response.body) as List<dynamic>;
    return data.map((item) => AppUser.fromApi(item as Map<String, dynamic>)).toList();
  }

  Future<AppUser> fetchUser(String id) async {
    final uri = Uri.parse('$baseUrl/users/$id');
    final response = await http.get(uri, headers: _headers(json: false));
    if (response.statusCode != 200) {
      throw Exception('Failed to load user');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return AppUser.fromApi(data);
  }

  Future<AppUser> updateUser(String id, Map<String, dynamic> payload) async {
    final uri = Uri.parse('$baseUrl/users/$id');
    final response = await http.patch(
      uri,
      headers: _headers(),
      body: jsonEncode(payload),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update user');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return AppUser.fromApi(data);
  }

  Future<AppUser> createUser(Map<String, dynamic> payload) async {
    final uri = Uri.parse('$baseUrl/users');
    final response = await http.post(
      uri,
      headers: _headers(),
      body: jsonEncode(payload),
    );
    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Failed to create user');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return AppUser.fromApi(data);
  }

  Future<void> deleteUser(String id) async {
    final uri = Uri.parse('$baseUrl/users/$id');
    final response = await http.delete(uri, headers: _headers(json: false));
    if (response.statusCode != 200) {
      throw Exception('Failed to delete user');
    }
  }
}
