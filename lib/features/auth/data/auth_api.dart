import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/api/api_config.dart';

class AuthApi {
  AuthApi({String? baseUrl}) : baseUrl = baseUrl ?? ApiConfig.baseUrl;

  final String baseUrl;

  Future<Map<String, dynamic>> login(String email, String password) async {
    final uri = Uri.parse('$baseUrl/auth/login');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Login failed');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String role,
    String? name,
  }) async {
    final uri = Uri.parse('$baseUrl/auth/register');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'role': role,
        if (name != null) 'name': name,
      }),
    );
    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Registration failed');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}
