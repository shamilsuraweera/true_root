import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_config.dart';
import '../data/batch_api.dart';
import '../models/batch.dart';

final batchListProvider = Provider<List<Batch>>((ref) {
  return [
    Batch(
      id: 'BATCH-001',
      product: 'Cinnamon',
      quantity: 120.5,
      status: 'ACTIVE',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    Batch(
      id: 'BATCH-002',
      product: 'Tea',
      quantity: 75,
      status: 'HOLD',
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
  ];
});

final batchByIdProvider = Provider.family<Batch?, String>((ref, batchId) {
  final batches = ref.watch(batchListProvider);
  try {
    return batches.firstWhere((b) => b.id == batchId);
  } catch (_) {
    return null;
  }
});

final batchApiProvider = Provider<BatchApi>((ref) {
  return const BatchApi(ApiConfig.baseUrl);
});

final batchQrPayloadProvider = FutureProvider.family<String, String>((ref, batchId) async {
  final api = ref.read(batchApiProvider);
  final normalized = _normalizeBatchId(batchId);
  if (normalized == null) {
    throw Exception('Invalid batch id');
  }
  return api.fetchQrPayload(normalized);
});

String? _normalizeBatchId(String batchId) {
  final numeric = int.tryParse(batchId);
  if (numeric != null) {
    return numeric.toString();
  }
  final digits = batchId.replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) {
    return null;
  }
  final parsed = int.tryParse(digits);
  return parsed?.toString();
}
