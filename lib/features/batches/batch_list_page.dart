import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'state/batch_provider.dart';
import 'batch_detail_page.dart';
import 'create_batch_page.dart';
import 'qr_scan_page.dart';
import '../products/state/product_provider.dart';

class BatchListPage extends ConsumerWidget {
  const BatchListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final batchesAsync = ref.watch(batchListProvider);
    final productsAsync = ref.watch(productListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Batches'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const QrScanPage()),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateBatchPage()),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: batchesAsync.when(
        data: (batches) {
          if (batches.isEmpty) {
            return const Center(child: Text('No batches yet'));
          }
          return productsAsync.when(
            data: (products) {
              final productMap = {
                for (final product in products) product.id: product.name,
              };
              return ListView.builder(
                itemCount: batches.length,
                itemBuilder: (context, index) {
                  final batch = batches[index];
                  final productName = batch.productId != null
                      ? productMap[batch.productId]
                      : null;
                  return ListTile(
                    title: Text(productName ?? batch.displayProduct),
                    subtitle: Text('${batch.quantity} ${batch.unit} • ${batch.status}'),
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
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => const Center(child: Text('Failed to load products')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(child: Text('Failed to load batches')),
      ),
    );
  }
}
