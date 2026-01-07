import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/batch.dart';

class BatchState {
  final List<Batch> batches;

  const BatchState({required this.batches});
}

class BatchNotifier extends StateNotifier<BatchState> {
  BatchNotifier() : super(const BatchState(batches: []));

  void loadMockBatches() {
    state = BatchState(
      batches: [
        Batch(
          id: 'BATCH-001',
          product: 'Cinnamon',
          quantity: 120.5,
          status: 'CREATED',
          createdAt: DateTime.now(),
        ),
        Batch(
          id: 'BATCH-002',
          product: 'Tea',
          quantity: 300,
          status: 'GRADED',
          createdAt: DateTime.now(),
        ),
      ],
    );
  }

  void clear() {
    state = const BatchState(batches: []);
  }
}

final batchProvider = StateNotifierProvider<BatchNotifier, BatchState>((ref) {
  return BatchNotifier();
});
