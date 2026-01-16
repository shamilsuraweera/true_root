import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/api/api_config.dart';
import '../../requests/models/ownership_request.dart';
import '../models/recent_activity.dart';

class DashboardApi {
  DashboardApi({String? baseUrl, this.authToken}) : baseUrl = baseUrl ?? ApiConfig.baseUrl;

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

  Future<List<OwnershipRequest>> fetchPendingRequests({required String ownerId, int limit = 5}) async {
    final uri = Uri.parse('$baseUrl/ownership-requests/inbox?ownerId=$ownerId&limit=$limit');
    final response = await http.get(uri, headers: _headers(json: false));
    if (response.statusCode != 200) {
      throw Exception('Failed to load requests');
    }
    final data = jsonDecode(response.body) as List<dynamic>;
    return data.map((item) => OwnershipRequest.fromApi(item as Map<String, dynamic>)).toList();
  }

  Future<List<RecentActivity>> fetchRecentActivity({int limit = 5}) async {
    final uri = Uri.parse('$baseUrl/batch-events/recent?limit=$limit');
    final response = await http.get(uri, headers: _headers(json: false));
    if (response.statusCode != 200) {
      throw Exception('Failed to load activity');
    }
    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((item) => RecentActivity.fromApi(item as Map<String, dynamic>))
        .toList();
  }
}
