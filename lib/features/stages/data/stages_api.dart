import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/api/api_config.dart';
import '../models/stage.dart';

class StagesApi {
  StagesApi({String? baseUrl, this.authToken}) : baseUrl = baseUrl ?? ApiConfig.baseUrl;

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

  Future<List<Stage>> fetchStages() async {
    final uri = Uri.parse('$baseUrl/stages');
    final response = await http.get(uri, headers: _headers(json: false));
    if (response.statusCode != 200) {
      throw Exception('Failed to load stages');
    }
    final data = jsonDecode(response.body) as List<dynamic>;
    return data.map((item) => Stage.fromApi(item as Map<String, dynamic>)).toList();
  }

  Future<Stage> createStage(Map<String, dynamic> payload) async {
    final uri = Uri.parse('$baseUrl/stages');
    final response = await http.post(
      uri,
      headers: _headers(),
      body: jsonEncode(payload),
    );
    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Failed to create stage');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return Stage.fromApi(data);
  }

  Future<Stage> updateStage(int id, Map<String, dynamic> payload) async {
    final uri = Uri.parse('$baseUrl/stages/$id');
    final response = await http.patch(
      uri,
      headers: _headers(),
      body: jsonEncode(payload),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update stage');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return Stage.fromApi(data);
  }

  Future<void> deleteStage(int id) async {
    final uri = Uri.parse('$baseUrl/stages/$id');
    final response = await http.delete(uri, headers: _headers(json: false));
    if (response.statusCode != 200) {
      throw Exception('Failed to delete stage');
    }
  }
}
