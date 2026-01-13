import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/batch.dart';

class BatchApi {
  const BatchApi(this.baseUrl);

  final String baseUrl;

  Future<String> fetchQrPayload(String batchId) async {
    final uri = Uri.parse('$baseUrl/batches/$batchId/qr');
    final response = await http.get(uri);
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
    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Failed to load batch');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return Batch.fromApi(data);
  }

  Future<List<Batch>> fetchBatches({int limit = 50, int offset = 0}) async {
    final uri = Uri.parse('$baseUrl/batches?limit=$limit&offset=$offset');
    final response = await http.get(uri);
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
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'items': items}),
    );
    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Failed to split batch');
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
      headers: {'Content-Type': 'application/json'},
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
      throw Exception('Failed to merge batches');
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
      headers: {'Content-Type': 'application/json'},
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
      throw Exception('Failed to transform batch');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Batch> createBatch({
    required int productId,
    required int quantity,
    String? grade,
  }) async {
    final uri = Uri.parse('$baseUrl/batches');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
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
      headers: {'Content-Type': 'application/json'},
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
    final response = await http.patch(uri);
    if (response.statusCode != 200) {
      throw Exception('Failed to archive batch');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return Batch.fromApi(data);
  }

  Future<void> deleteBatch(String batchId) async {
    final uri = Uri.parse('$baseUrl/batches/$batchId');
    final response = await http.delete(uri);
    if (response.statusCode != 200) {
      throw Exception('Failed to delete batch');
    }
  }
}
