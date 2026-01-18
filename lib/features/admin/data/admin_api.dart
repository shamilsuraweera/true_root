import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/api/api_config.dart';
import '../models/admin_overview.dart';

class AdminApi {
  AdminApi({String? baseUrl, this.authToken}) : baseUrl = baseUrl ?? ApiConfig.baseUrl;

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

  Future<AdminOverview> fetchOverview({int limit = 10}) async {
    final uri = Uri.parse('$baseUrl/admin/overview?limit=$limit');
    final response = await http.get(uri, headers: _headers(json: false));
    if (response.statusCode != 200) {
      throw Exception('Failed to load admin overview');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return AdminOverview.fromApi(data);
  }
}
