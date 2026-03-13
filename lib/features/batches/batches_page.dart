import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'state/batch_provider.dart';
import 'models/batch.dart';

class BatchesPage extends ConsumerWidget {
  const BatchesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final batchesAsync = ref.watch(batchListProvider);
    final cachedBatches = ref.watch(cachedBatchListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Batches')),
      body: batchesAsync.when(
        data: (batches) {
          if (batches.isEmpty) {
            return const Center(child: Text('No batches yet'));
          }
          return ListView.builder(
            itemCount: batches.length,
            itemBuilder: (context, index) {
              final Batch batch = batches[index];
              return ListTile(
                title: Text('Batch ${batch.id} • ${batch.displayProduct}'),
                subtitle: Text('${batch.quantity} ${batch.unit}'),
                trailing: Text(batch.status),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) {
          if (cachedBatches.isNotEmpty) {
            return ListView.builder(
              itemCount: cachedBatches.length,
              itemBuilder: (context, index) {
                final Batch batch = cachedBatches[index];
                return ListTile(
                  title: Text('Batch ${batch.id} • ${batch.displayProduct}'),
                  subtitle: Text('${batch.quantity} ${batch.unit}'),
                  trailing: Text(batch.status),
                );
              },
            );
          }
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Failed to load batches'),
                TextButton(
                  onPressed: () => ref.invalidate(batchListProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
