import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'state/batch_provider.dart';
import 'models/batch.dart';

class BatchesPage extends ConsumerWidget {
  const BatchesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final batches = ref.watch(batchListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Batches')),
      body: ListView.builder(
        itemCount: batches.length,
        itemBuilder: (context, index) {
          final Batch batch = batches[index];
          return ListTile(
            title: Text(batch.id),
            subtitle: Text('${batch.product} • ${batch.quantity} kg'),
            trailing: Text(batch.status),
          );
        },
      ),
    );
  }
}
