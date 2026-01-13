import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'batch_history_timeline.dart';
import 'state/batch_provider.dart';

class BatchDetailPage extends ConsumerWidget {
  final String batchId;

  const BatchDetailPage({super.key, required this.batchId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final batch = ref.watch(batchByIdProvider(batchId));

    if (batch == null) {
      return const Scaffold(body: Center(child: Text('Batch not found')));
    }

    return Scaffold(
      appBar: AppBar(title: Text('Batch ${batch.id}')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(batch.product, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('Quantity: ${batch.quantity}'),
            Text('Status: ${batch.status}'),
            Text('Created: ${batch.createdAt}'),
            const SizedBox(height: 16),
            Text('QR Code', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            _QrPayloadView(batchId: batch.id),
            const SizedBox(height: 24),
            const Text(
              'History',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Expanded(child: BatchHistoryTimeline()),
          ],
        ),
      ),
    );
  }
}

class _QrPayloadView extends ConsumerWidget {
  final String batchId;

  const _QrPayloadView({required this.batchId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final qrPayload = ref.watch(batchQrPayloadProvider(batchId));

    return qrPayload.when(
      data: (payload) => Center(
        child: QrImageView(
          data: payload,
          size: 180,
          backgroundColor: Colors.white,
        ),
      ),
      loading: () => const SizedBox(
        height: 180,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stackTrace) => SizedBox(
        height: 180,
        child: Center(
          child: Text(
            'Failed to load QR',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ),
    );
  }
}
