import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/api/api_config.dart';
import '../models/user.dart';

class UsersApi {
  UsersApi({String? baseUrl}) : baseUrl = baseUrl ?? ApiConfig.baseUrl;

  final String baseUrl;

  Future<List<AppUser>> fetchUsers() async {
    final uri = Uri.parse('$baseUrl/users');
    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Failed to load users');
    }
    final data = jsonDecode(response.body) as List<dynamic>;
    return data.map((item) => AppUser.fromApi(item as Map<String, dynamic>)).toList();
  }

  Future<AppUser> fetchUser(String id) async {
    final uri = Uri.parse('$baseUrl/users/$id');
    final response = await http.get(uri);
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
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update user');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return AppUser.fromApi(data);
  }
}
