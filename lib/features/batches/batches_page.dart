import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'state/batch_provider.dart';
import 'models/batch.dart';

class BatchesPage extends ConsumerWidget {
  const BatchesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final batchesAsync = ref.watch(batchListProvider);

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
        error: (_, _) => const Center(child: Text('Failed to load batches')),
      ),
    );
  }
}
