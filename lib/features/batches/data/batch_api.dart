import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/batch.dart';
import '../models/batch_event.dart';
import '../models/batch_lineage.dart';

class BatchApi {
  const BatchApi(this.baseUrl, {this.authToken});

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

  String _errorMessage(http.Response response, String fallback) {
    try {
      final data = jsonDecode(response.body);
      if (data is Map<String, dynamic>) {
        final message = data['message'];
        if (message is String && message.isNotEmpty) {
          return message;
        }
        if (message is List && message.isNotEmpty) {
          return message.map((item) => item.toString()).join(', ');
        }
      }
    } catch (_) {}
    return fallback;
  }

  Future<String> fetchQrPayload(String batchId) async {
    final uri = Uri.parse('$baseUrl/batches/$batchId/qr');
    final response = await http.get(uri, headers: _headers(json: false));
    if (response.statusCode != 200) {
      throw Exception('Failed to load QR payload');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final payload = data['payload'];
    if (payload is! String || payload.isEmpty) {
      throw Exception('Invalid QR payload');
    }
    return payload;
  }

  Future<Batch> fetchBatch(String batchId) async {
    final uri = Uri.parse('$baseUrl/batches/$batchId');
    final response = await http.get(uri, headers: _headers(json: false));
    if (response.statusCode != 200) {
      throw Exception('Failed to load batch');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return Batch.fromApi(data);
  }

  Future<List<BatchEvent>> fetchBatchHistory(String batchId) async {
    final uri = Uri.parse('$baseUrl/batches/$batchId/history');
    final response = await http.get(uri, headers: _headers(json: false));
    if (response.statusCode != 200) {
      throw Exception('Failed to load batch history');
    }
    final data = jsonDecode(response.body) as List<dynamic>;
    return data.map((item) => BatchEvent.fromApi(item as Map<String, dynamic>)).toList();
  }

  Future<BatchLineage> fetchBatchLineage(String batchId) async {
    final uri = Uri.parse('$baseUrl/batches/$batchId/lineage');
    final response = await http.get(uri, headers: _headers(json: false));
    if (response.statusCode != 200) {
      throw Exception('Failed to load batch lineage');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return BatchLineage.fromApi(data);
  }

  Future<List<Batch>> fetchBatches({
    int limit = 50,
    int offset = 0,
    String? ownerId,
    bool includeInactive = false,
  }) async {
    final query = StringBuffer('limit=$limit&offset=$offset');
    if (ownerId != null) {
      query.write('&ownerId=$ownerId');
    }
    if (includeInactive) {
      query.write('&includeInactive=true');
    }
    final uri = Uri.parse('$baseUrl/batches?$query');
    final response = await http.get(uri, headers: _headers(json: false));
    if (response.statusCode != 200) {
      throw Exception('Failed to load batches');
    }
    final data = jsonDecode(response.body) as List<dynamic>;
    return data.map((item) => Batch.fromApi(item as Map<String, dynamic>)).toList();
  }

  Future<Map<String, dynamic>> splitBatch(String batchId, List<Map<String, dynamic>> items) async {
    final uri = Uri.parse('$baseUrl/batches/$batchId/split');
    final response = await http.post(
      uri,
      headers: _headers(),
      body: jsonEncode({'items': items}),
    );
    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception(_errorMessage(response, 'Failed to split batch'));
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Batch> mergeBatches({
    required List<int> batchIds,
    required int productId,
    String? grade,
    String? status,
    int? stageId,
    String? unit,
  }) async {
    final uri = Uri.parse('$baseUrl/batches/merge');
    final response = await http.post(
      uri,
      headers: _headers(),
      body: jsonEncode({
        'batchIds': batchIds,
        'productId': productId,
        if (grade != null) 'grade': grade,
        if (status != null) 'status': status,
        if (stageId != null) 'stageId': stageId,
        if (unit != null) 'unit': unit,
      }),
    );
    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception(_errorMessage(response, 'Failed to merge batches'));
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return Batch.fromApi(data);
  }

  Future<Map<String, dynamic>> transformBatch({
    required String batchId,
    required int productId,
    double? quantity,
    String? grade,
    String? status,
    int? stageId,
    String? unit,
  }) async {
    final uri = Uri.parse('$baseUrl/batches/$batchId/transform');
    final response = await http.post(
      uri,
      headers: _headers(),
      body: jsonEncode({
        'productId': productId,
        if (quantity != null) 'quantity': quantity,
        if (grade != null) 'grade': grade,
        if (status != null) 'status': status,
        if (stageId != null) 'stageId': stageId,
        if (unit != null) 'unit': unit,
      }),
    );
    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception(_errorMessage(response, 'Failed to transform batch'));
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Batch> updateQuantity(String batchId, double quantity) async {
    final uri = Uri.parse('$baseUrl/batches/$batchId/quantity');
    final response = await http.patch(
      uri,
      headers: _headers(),
      body: jsonEncode({'quantity': quantity}),
    );
    if (response.statusCode != 200) {
      throw Exception(_errorMessage(response, 'Failed to update quantity'));
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return Batch.fromApi(data);
  }

  Future<Batch> updateStatus(String batchId, String status) async {
    final uri = Uri.parse('$baseUrl/batches/$batchId/status');
    final response = await http.patch(
      uri,
      headers: _headers(),
      body: jsonEncode({'status': status}),
    );
    if (response.statusCode != 200) {
      throw Exception(_errorMessage(response, 'Failed to update status'));
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return Batch.fromApi(data);
  }

  Future<Batch> updateGrade(String batchId, String grade) async {
    final uri = Uri.parse('$baseUrl/batches/$batchId/grade');
    final response = await http.patch(
      uri,
      headers: _headers(),
      body: jsonEncode({'grade': grade}),
    );
    if (response.statusCode != 200) {
      throw Exception(_errorMessage(response, 'Failed to update grade'));
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return Batch.fromApi(data);
  }

  Future<Batch> createBatch({
    required int productId,
    required int quantity,
    String? grade,
  }) async {
    final uri = Uri.parse('$baseUrl/batches');
    final response = await http.post(
      uri,
      headers: _headers(),
      body: jsonEncode({
        'productId': productId,
        'quantity': quantity,
        if (grade != null) 'grade': grade,
      }),
    );
    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Failed to create batch');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return Batch.fromApi(data);
  }

  Future<Batch> disqualifyBatch(String batchId, String reason) async {
    final uri = Uri.parse('$baseUrl/batches/$batchId/disqualify');
    final response = await http.patch(
      uri,
      headers: _headers(),
      body: jsonEncode({'reason': reason}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to disqualify batch');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return Batch.fromApi(data);
  }

  Future<Batch> archiveBatch(String batchId) async {
    final uri = Uri.parse('$baseUrl/batches/$batchId/archive');
    final response = await http.patch(uri, headers: _headers(json: false));
    if (response.statusCode != 200) {
      throw Exception('Failed to archive batch');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return Batch.fromApi(data);
  }

  Future<void> deleteBatch(String batchId) async {
    final uri = Uri.parse('$baseUrl/batches/$batchId');
    final response = await http.delete(uri, headers: _headers(json: false));
    if (response.statusCode != 200) {
      throw Exception('Failed to delete batch');
    }
  }
}
