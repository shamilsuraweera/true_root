import 'package:flutter_riverpod/flutter_riverpod.dart';
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
