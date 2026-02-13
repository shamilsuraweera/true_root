import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_config.dart';
import '../data/batch_api.dart';
import '../models/batch.dart';
import '../models/batch_event.dart';
import '../models/batch_lineage.dart';
import '../../../state/auth_state.dart';
import '../../profile/state/profile_provider.dart';

final batchListProvider = FutureProvider<List<Batch>>((ref) async {
  final api = ref.watch(batchApiProvider);
  return api.fetchBatches(limit: 50);
});

final ownedBatchListProvider = FutureProvider<List<Batch>>((ref) async {
  final api = ref.watch(batchApiProvider);
  final ownerId = ref.read(currentUserIdProvider);
  return api.fetchBatches(limit: 50, ownerId: ownerId, includeInactive: true);
});

final batchSearchProvider = StateProvider<String>((ref) => '');

final batchByIdProvider = FutureProvider.family<Batch?, String>((ref, batchId) async {
  final api = ref.watch(batchApiProvider);
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
  final token = ref.watch(authProvider).accessToken;
  return BatchApi(ApiConfig.baseUrl, authToken: token);
});

final batchQrPayloadProvider = FutureProvider.family<String, String>((ref, batchId) async {
  final api = ref.watch(batchApiProvider);
  final normalized = _normalizeBatchId(batchId);
  if (normalized == null) {
    throw Exception('Invalid batch id');
  }
  return api.fetchQrPayload(normalized);
});

final batchHistoryProvider = FutureProvider.family<List<BatchEvent>, String>((ref, batchId) async {
  final api = ref.watch(batchApiProvider);
  final normalized = _normalizeBatchId(batchId);
  if (normalized == null) {
    throw Exception('Invalid batch id');
  }
  return api.fetchBatchHistory(normalized);
});

final batchLineageProvider = FutureProvider.family<BatchLineage, String>((ref, batchId) async {
  final api = ref.watch(batchApiProvider);
  final normalized = _normalizeBatchId(batchId);
  if (normalized == null) {
    throw Exception('Invalid batch id');
  }
  return api.fetchBatchLineage(normalized);
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
