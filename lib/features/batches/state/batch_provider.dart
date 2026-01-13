import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_config.dart';
import '../data/batch_api.dart';
import '../models/batch.dart';

final batchListProvider = FutureProvider<List<Batch>>((ref) async {
  final api = ref.read(batchApiProvider);
  return api.fetchBatches(limit: 50);
});

final batchByIdProvider = FutureProvider.family<Batch?, String>((ref, batchId) async {
  final api = ref.read(batchApiProvider);
  final normalized = _normalizeBatchId(batchId);
  if (normalized == null) {
    throw Exception('Invalid batch id');
  }

  try {
    return await api.fetchBatch(normalized);
  } catch (_) {
    final batches = await ref.read(batchListProvider.future);
    try {
      return batches.firstWhere((b) => b.id == batchId);
    } catch (_) {
      rethrow;
    }
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
