import 'dart:convert';
import 'package:http/http.dart' as http;

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
}
