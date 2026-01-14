import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/api/api_config.dart';
import '../../requests/models/ownership_request.dart';
import '../models/recent_activity.dart';

class DashboardApi {
  DashboardApi({String? baseUrl}) : baseUrl = baseUrl ?? ApiConfig.baseUrl;

  final String baseUrl;

  Future<List<OwnershipRequest>> fetchPendingRequests({required String ownerId, int limit = 5}) async {
    final uri = Uri.parse('$baseUrl/ownership-requests/inbox?ownerId=$ownerId&limit=$limit');
    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Failed to load requests');
    }
    final data = jsonDecode(response.body) as List<dynamic>;
    return data.map((item) => OwnershipRequest.fromApi(item as Map<String, dynamic>)).toList();
  }

  Future<List<RecentActivity>> fetchRecentActivity({int limit = 5}) async {
    final uri = Uri.parse('$baseUrl/batch-events/recent?limit=$limit');
    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Failed to load activity');
    }
    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((item) => RecentActivity.fromApi(item as Map<String, dynamic>))
        .toList();
  }
}
