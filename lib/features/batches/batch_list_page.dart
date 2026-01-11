import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'state/batch_provider.dart';
import 'batch_detail_page.dart';

class BatchListPage extends ConsumerWidget {
  const BatchListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final batches = ref.watch(batchListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Batches')),
      body: ListView.builder(
        itemCount: batches.length,
        itemBuilder: (context, index) {
          final batch = batches[index];
          return ListTile(
            title: Text(batch.product),
            subtitle: Text('${batch.quantity} kg • ${batch.status}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BatchDetailPage(batchId: batch.id),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
