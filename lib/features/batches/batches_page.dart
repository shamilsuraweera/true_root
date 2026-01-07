import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'state/batch_provider.dart';

class BatchesPage extends ConsumerWidget {
  const BatchesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final batchState = ref.watch(batchProvider);

    return Scaffold(
      body: ListView.builder(
        itemCount: batchState.batches.length,
        itemBuilder: (context, index) {
          final batch = batchState.batches[index];

          return ListTile(
            title: Text(batch.product),
            subtitle: Text('Qty: ${batch.quantity} | Status: ${batch.status}'),
            trailing: Text(batch.id),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ref.read(batchProvider.notifier).loadMockBatches();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
