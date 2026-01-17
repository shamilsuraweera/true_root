import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/api/api_config.dart';
import '../models/ownership_request.dart';

class OwnershipRequestsApi {
  OwnershipRequestsApi({String? baseUrl, this.authToken}) : baseUrl = baseUrl ?? ApiConfig.baseUrl;

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

  Future<OwnershipRequest> createRequest({
    required String batchId,
    required String requesterId,
    required String ownerId,
    required double quantity,
    String? note,
  }) async {
    final uri = Uri.parse('$baseUrl/ownership-requests');
    final response = await http.post(
      uri,
      headers: _headers(),
      body: jsonEncode({
        'batchId': int.parse(batchId),
        'requesterId': int.parse(requesterId),
        'ownerId': int.parse(ownerId),
        'quantity': quantity,
        if (note != null) 'note': note,
      }),
    );
    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Failed to create request');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return OwnershipRequest.fromApi(data);
  }

  Future<List<OwnershipRequest>> fetchInbox(String ownerId) async {
    final uri = Uri.parse('$baseUrl/ownership-requests/inbox?ownerId=$ownerId');
    final response = await http.get(uri, headers: _headers(json: false));
    if (response.statusCode != 200) {
      throw Exception('Failed to load inbox');
    }
    final data = jsonDecode(response.body) as List<dynamic>;
    return data.map((item) => OwnershipRequest.fromApi(item as Map<String, dynamic>)).toList();
  }

  Future<List<OwnershipRequest>> fetchOutbox(String requesterId) async {
    final uri = Uri.parse('$baseUrl/ownership-requests/outbox?requesterId=$requesterId');
    final response = await http.get(uri, headers: _headers(json: false));
    if (response.statusCode != 200) {
      throw Exception('Failed to load outbox');
    }
    final data = jsonDecode(response.body) as List<dynamic>;
    return data.map((item) => OwnershipRequest.fromApi(item as Map<String, dynamic>)).toList();
  }

  Future<void> approve(String requestId) async {
    final uri = Uri.parse('$baseUrl/ownership-requests/$requestId/approve');
    final response = await http.patch(uri, headers: _headers(json: false));
    if (response.statusCode != 200) {
      throw Exception('Failed to approve request');
    }
  }

  Future<void> reject(String requestId, {String? note}) async {
    final uri = Uri.parse('$baseUrl/ownership-requests/$requestId/reject');
    final response = await http.patch(
      uri,
      headers: _headers(),
      body: jsonEncode({
        if (note != null) 'note': note,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to reject request');
    }
  }
}
