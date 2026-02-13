import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'state/batch_provider.dart';
import 'batch_detail_page.dart';
import 'create_batch_page.dart';
import 'qr_scan_page.dart';
import '../products/state/product_provider.dart';
import '../requests/models/ownership_request.dart';
import '../requests/state/ownership_requests_provider.dart';
import 'models/batch.dart';

class BatchListPage extends ConsumerStatefulWidget {
  const BatchListPage({super.key});

  @override
  ConsumerState<BatchListPage> createState() => _BatchListPageState();
}

class _BatchListPageState extends ConsumerState<BatchListPage> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController =
        TextEditingController(text: ref.read(batchSearchProvider));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleSearchChanged(String value) {
    ref.read(batchSearchProvider.notifier).state = value;
  }

  List<Batch> _filterBatches(
    List<Batch> items,
    Map<int, String> productMap,
    String query,
  ) {
    if (query.trim().isEmpty) return items;
    final normalized = query.toLowerCase();
    final digits = query.replaceAll(RegExp(r'\D'), '');
    final queryId = int.tryParse(digits);
    return items.where((batch) {
      if (queryId != null && batch.id == queryId.toString()) {
        return true;
      }
      final displayProduct = productMap[batch.productId ?? -1] ?? batch.displayProduct;
      final text = 'batch ${batch.id} $displayProduct ${batch.status} ${batch.ownerName ?? ''}'
          .toLowerCase();
      return text.contains(normalized);
    }).toList();
  }

  List<OwnershipRequest> _filterRequests(
    List<OwnershipRequest> items,
    String query,
  ) {
    if (query.trim().isEmpty) return items;
    final normalized = query.toLowerCase();
    final digits = query.replaceAll(RegExp(r'\D'), '');
    final queryBatchId = int.tryParse(digits)?.toString();
    return items.where((request) {
      if (queryBatchId != null && request.batchId == queryBatchId) {
        return true;
      }
      final text = '${request.batchId} ${request.requesterId} ${request.status} ${request.quantity}'
          .toLowerCase();
      return text.contains(normalized);
    }).toList();
  }
  @override
  Widget build(BuildContext context) {
    final batchesAsync = ref.watch(ownedBatchListProvider);
    final productsAsync = ref.watch(productListProvider);
    final searchQuery = ref.watch(batchSearchProvider);
    if (_searchController.text != searchQuery) {
      _searchController.value = TextEditingValue(
        text: searchQuery,
        selection: TextSelection.collapsed(offset: searchQuery.length),
      );
    }
    final outboxAsync = ref.watch(ownershipOutboxProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
          appBar: AppBar(
            title: _AppSearchField(
              hintText: 'Search batches',
              controller: _searchController,
              onChanged: _handleSearchChanged,
            ),
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
            IconButton(
              icon: const Icon(Icons.notifications_none),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('No notifications')),
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
                    final Map<int, String> productMap = {
                      for (final product in products) product.id: product.name,
                    };
                    final filteredBatches =
                        _filterBatches(batches, productMap, searchQuery);
                    final emptyBatchMessage = searchQuery.isEmpty
                        ? 'No batches yet'
                        : 'No matching batches';
                    if (filteredBatches.isEmpty) {
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
                            children: [
                              const SizedBox(height: 200),
                              Center(child: Text(emptyBatchMessage)),
                            ],
                        ),
                      );
                    }
                    return RefreshIndicator(
                      onRefresh: () async {
                        ref.invalidate(ownedBatchListProvider);
                        ref.invalidate(productListProvider);
                        await Future.wait([
                          ref.read(ownedBatchListProvider.future),
                          ref.read(productListProvider.future),
                        ]);
                      },
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                        itemCount: filteredBatches.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final batch = filteredBatches[index];
                          final productName = batch.productId != null
                              ? productMap[batch.productId]
                              : null;
                          return _BatchCard(
                            title:
                                'Batch ${batch.id} • ${productName ?? batch.displayProduct}',
                            subtitle:
                                '${batch.quantity} ${batch.unit} • ${batch.status}',
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      BatchDetailPage(batchId: batch.id),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, _) =>
                      const Center(child: Text('Failed to load products')),
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
                final pending = requests
                    .where((item) => item.status == 'PENDING')
                    .toList();
                final filteredPending = _filterRequests(pending, searchQuery);
                final emptyPendingMessage = searchQuery.isEmpty
                    ? 'No pending requests'
                    : 'No matching requests';
                if (filteredPending.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(ownershipOutboxProvider);
                      await ref.read(ownershipOutboxProvider.future);
                    },
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        const SizedBox(height: 200),
                        Center(child: Text(emptyPendingMessage)),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(ownershipOutboxProvider);
                    await ref.read(ownershipOutboxProvider.future);
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    itemCount: filteredPending.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final request = filteredPending[index];
                      return Consumer(
                        builder: (context, ref, _) {
                          final batchAsync = ref.watch(
                            batchByIdProvider(request.batchId),
                          );
                          final products = ref
                              .watch(productListProvider)
                              .valueOrNull;
                          final productMap = {
                            for (final product in products ?? [])
                              product.id: product.name,
                          };
                          final batch = batchAsync.valueOrNull;
                          final productName = batch?.productId != null
                              ? productMap[batch!.productId]
                              : null;
                          return _BatchCard(
                            title:
                                'Batch ${request.batchId} • ${productName ?? batch?.displayProduct ?? 'Product'}',
                            subtitle:
                                '${request.quantity} ${batch?.unit ?? 'kg'} • ${batch?.status ?? request.status}',
                            trailing: _StatusPill(label: request.status),
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

class _AppSearchField extends StatelessWidget {
  final String hintText;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;

  const _AppSearchField({
    required this.hintText,
    this.controller,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hintText,
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surface,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(999),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(999),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ),
        onChanged: onChanged,
      ),
    );
  }
}

class _BatchCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _BatchCard({
    required this.title,
    required this.subtitle,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.surface,
      elevation: 0.6,
      borderRadius: BorderRadius.circular(16),
      shadowColor: colorScheme.shadow.withValues(alpha: 0.12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 12), trailing!],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;

  const _StatusPill({required this.label});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
