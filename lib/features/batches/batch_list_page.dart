import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'state/batch_provider.dart';
import 'batch_detail_page.dart';
import 'create_batch_page.dart';
import 'qr_scan_page.dart';
import '../products/state/product_provider.dart';
import '../requests/state/ownership_requests_provider.dart';

class BatchListPage extends ConsumerStatefulWidget {
  const BatchListPage({super.key});

  @override
  ConsumerState<BatchListPage> createState() => _BatchListPageState();
}

class _BatchListPageState extends ConsumerState<BatchListPage> {
  @override
  Widget build(BuildContext context) {
    final batchesAsync = ref.watch(ownedBatchListProvider);
    final productsAsync = ref.watch(productListProvider);
    final outboxAsync = ref.watch(ownershipOutboxProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
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
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Owned'),
              Tab(text: 'Pending'),
            ],
          ),
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
        body: TabBarView(
          children: [
            batchesAsync.when(
              data: (batches) {
                if (batches.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(ownedBatchListProvider);
                      ref.invalidate(productListProvider);
                      await Future.wait([
                        ref.read(ownedBatchListProvider.future),
                        ref.read(productListProvider.future),
                      ]);
                    },
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 200),
                        Center(child: Text('No batches yet')),
                      ],
                    ),
                  );
                }
                return productsAsync.when(
                  data: (products) {
                    final productMap = {
                      for (final product in products) product.id: product.name,
                    };
                    return RefreshIndicator(
                      onRefresh: () async {
                        ref.invalidate(ownedBatchListProvider);
                        ref.invalidate(productListProvider);
                        await Future.wait([
                          ref.read(ownedBatchListProvider.future),
                          ref.read(productListProvider.future),
                        ]);
                      },
                      child: ListView.builder(
                        itemCount: batches.length,
                        itemBuilder: (context, index) {
                          final batch = batches[index];
                          final productName = batch.productId != null
                              ? productMap[batch.productId]
                              : null;
                          return ListTile(
                            title: Text('Batch ${batch.id} • ${productName ?? batch.displayProduct}'),
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
                      ),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (_, _) => const Center(child: Text('Failed to load products')),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(ownedBatchListProvider);
                  ref.invalidate(productListProvider);
                  await Future.wait([
                    ref.read(ownedBatchListProvider.future),
                    ref.read(productListProvider.future),
                  ]);
                },
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    SizedBox(height: 200),
                    Center(child: Text('Failed to load batches')),
                  ],
                ),
              ),
            ),
            outboxAsync.when(
              data: (requests) {
                final pending = requests.where((item) => item.status == 'PENDING').toList();
                if (pending.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(ownershipOutboxProvider);
                      await ref.read(ownershipOutboxProvider.future);
                    },
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 200),
                        Center(child: Text('No pending requests')),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(ownershipOutboxProvider);
                    await ref.read(ownershipOutboxProvider.future);
                  },
                  child: ListView.builder(
                    itemCount: pending.length,
                    itemBuilder: (context, index) {
                      final request = pending[index];
                      return Consumer(
                        builder: (context, ref, _) {
                          final batchAsync = ref.watch(batchByIdProvider(request.batchId));
                          final products = ref.watch(productListProvider).valueOrNull;
                          final productMap = {
                            for (final product in products ?? []) product.id: product.name,
                          };
                          final batch = batchAsync.valueOrNull;
                          final productName = batch?.productId != null
                              ? productMap[batch!.productId]
                              : null;
                          return ListTile(
                            title: Text(
                              'Batch ${request.batchId} • ${productName ?? batch?.displayProduct ?? 'Product'}',
                            ),
                            subtitle: Text(
                              '${request.quantity} ${batch?.unit ?? 'kg'} • ${batch?.status ?? request.status}',
                            ),
                            trailing: const Icon(Icons.hourglass_top),
                          );
                        },
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(ownershipOutboxProvider);
                  await ref.read(ownershipOutboxProvider.future);
                },
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    SizedBox(height: 200),
                    Center(child: Text('Failed to load requests')),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
