import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/app_widgets.dart';
import 'state/batch_provider.dart';
import 'batch_detail_page.dart';
import 'create_batch_page.dart';
import 'qr_scan_page.dart';
import '../products/state/product_provider.dart';
import '../requests/models/ownership_request.dart';
import '../requests/state/ownership_requests_provider.dart';
import 'models/batch.dart';
import '../notifications/notifications_sheet.dart';

class BatchListPage extends ConsumerStatefulWidget {
  const BatchListPage({super.key});

  @override
  ConsumerState<BatchListPage> createState() => _BatchListPageState();
}

class _BatchListPageState extends ConsumerState<BatchListPage> {
  late final TextEditingController _searchController;
  String _selectedStatus = 'ALL';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: ref.read(batchSearchProvider),
    );
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
    var result = items;
    if (_selectedStatus != 'ALL') {
      result = result
          .where((b) => b.status.toUpperCase() == _selectedStatus)
          .toList();
    }
    if (query.trim().isEmpty) return result;
    final normalized = query.toLowerCase();
    final digits = query.replaceAll(RegExp(r'\D'), '');
    final queryId = int.tryParse(digits);
    return result.where((batch) {
      if (queryId != null && batch.id == queryId.toString()) {
        return true;
      }
      final displayProduct =
          productMap[batch.productId ?? -1] ?? batch.displayProduct;
      final text =
          'batch ${batch.id} $displayProduct ${batch.status} ${batch.ownerName ?? ''}'
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
      final text =
          '${request.batchId} ${request.requesterId} ${request.status} ${request.quantity}'
              .toLowerCase();
      return text.contains(normalized);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final batchesAsync = ref.watch(ownedBatchListProvider);
    final productsAsync = ref.watch(productListProvider);
    final searchQuery = ref.watch(batchSearchProvider);
    final cachedOwnedBatches = ref.watch(cachedOwnedBatchListProvider);
    final cachedOutbox = ref.watch(cachedOwnershipOutboxProvider);
    final Map<int, String> cachedProductMap = {
      for (final product in productsAsync.value ?? []) product.id: product.name,
    };
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
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CreateBatchPage()),
            );
          },
          icon: const Icon(Icons.add),
          label: const Text('New Batch'),
        ),
        body: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                MediaQuery.paddingOf(context).top + 12,
                16,
                18,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: AppSearchField(
                          hint: 'Search batches by ID or name...',
                          controller: _searchController,
                          onChanged: _handleSearchChanged,
                        ),
                      ),
                      const SizedBox(width: 10),
                      IconButton.filledTonal(
                        icon: Icon(Icons.qr_code_scanner),
                        tooltip: 'Scan QR Code',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const QrScanPage(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                        icon: Icon(Icons.notifications_none),
                        tooltip: 'Notifications',
                        onPressed: () {
                          showNotificationsSheet(context, ref);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Track Lot Traceability',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Monitor your active harvest, inventory, and pending ownership transfers.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ContentWidth(
                child: Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(12, 12, 12, 4),
                      child: TabBar(
                        tabs: [
                          Tab(text: 'My Batches'),
                          Tab(text: 'Pending Requests'),
                        ],
                      ),
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          // Tab 1: Owned Batches
                          Column(
                            children: [
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                child: Row(
                                  children:
                                      [
                                        'ALL',
                                        'ACTIVE',
                                        'TRANSFERRED',
                                        'SPLIT',
                                        'MERGED',
                                        'ARCHIVED',
                                        'DISQUALIFIED',
                                      ].map((status) {
                                        final isSelected =
                                            _selectedStatus == status;
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                            right: 8,
                                          ),
                                          child: FilterChip(
                                            label: Text(
                                              status,
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: isSelected
                                                    ? FontWeight.bold
                                                    : FontWeight.normal,
                                              ),
                                            ),
                                            selected: isSelected,
                                            onSelected: (selected) {
                                              setState(
                                                () => _selectedStatus = selected
                                                    ? status
                                                    : 'ALL',
                                              );
                                            },
                                          ),
                                        );
                                      }).toList(),
                                ),
                              ),
                              Expanded(
                                child: batchesAsync.when(
                                  data: (batches) {
                                    if (batches.isEmpty) {
                                      return RefreshIndicator(
                                        onRefresh: () async {
                                          ref.invalidate(
                                            ownedBatchListProvider,
                                          );
                                          ref.invalidate(productListProvider);
                                          await Future.wait([
                                            ref.read(
                                              ownedBatchListProvider.future,
                                            ),
                                            ref.read(
                                              productListProvider.future,
                                            ),
                                          ]);
                                        },
                                        child: ListView(
                                          physics:
                                              const AlwaysScrollableScrollPhysics(),
                                          children: const [
                                            SizedBox(height: 80),
                                            EmptyState(
                                              icon: Icons.inventory_2_outlined,
                                              title: 'No batches yet',
                                              message:
                                                  'Batches in your inventory will appear here.',
                                            ),
                                          ],
                                        ),
                                      );
                                    }
                                    return productsAsync.when(
                                      data: (products) {
                                        final Map<int, String> productMap = {
                                          for (final product in products)
                                            product.id: product.name,
                                        };
                                        final filteredBatches = _filterBatches(
                                          batches,
                                          productMap,
                                          searchQuery,
                                        );
                                        if (filteredBatches.isEmpty) {
                                          return ListView(
                                            physics:
                                                const AlwaysScrollableScrollPhysics(),
                                            children: const [
                                              SizedBox(height: 120),
                                              Center(
                                                child: Text(
                                                  'No batches matching your filter',
                                                ),
                                              ),
                                            ],
                                          );
                                        }
                                        return RefreshIndicator(
                                          onRefresh: () async {
                                            ref.invalidate(
                                              ownedBatchListProvider,
                                            );
                                            ref.invalidate(productListProvider);
                                            await Future.wait([
                                              ref.read(
                                                ownedBatchListProvider.future,
                                              ),
                                              ref.read(
                                                productListProvider.future,
                                              ),
                                            ]);
                                          },
                                          child: ListView.separated(
                                            padding: const EdgeInsets.fromLTRB(
                                              16,
                                              12,
                                              16,
                                              80,
                                            ),
                                            itemCount: filteredBatches.length,
                                            separatorBuilder: (context, _) =>
                                                const SizedBox(height: 10),
                                            itemBuilder: (context, index) {
                                              final batch =
                                                  filteredBatches[index];
                                              final productName =
                                                  batch.productId != null
                                                  ? productMap[batch.productId]
                                                  : null;
                                              return _BatchCard(
                                                title:
                                                    'Batch #${batch.id}: ${productName ?? batch.displayProduct}',
                                                subtitle:
                                                    '${batch.quantity} ${batch.unit} • ${batch.grade ?? 'Standard'}',
                                                status: batch.status,
                                                trailing: const Icon(
                                                  Icons.chevron_right,
                                                ),
                                                onTap: () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (_) =>
                                                          BatchDetailPage(
                                                            batchId: batch.id,
                                                          ),
                                                    ),
                                                  );
                                                },
                                              );
                                            },
                                          ),
                                        );
                                      },
                                      loading: () => const Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                      error: (_, _) => const Center(
                                        child: Text('Failed to load products'),
                                      ),
                                    );
                                  },
                                  loading: () => const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                  error: (_, _) {
                                    if (cachedOwnedBatches.isNotEmpty) {
                                      final filtered = _filterBatches(
                                        cachedOwnedBatches,
                                        cachedProductMap,
                                        searchQuery,
                                      );
                                      return ListView.separated(
                                        padding: const EdgeInsets.fromLTRB(
                                          16,
                                          12,
                                          16,
                                          80,
                                        ),
                                        itemCount: filtered.length,
                                        separatorBuilder: (context, _) =>
                                            const SizedBox(height: 10),
                                        itemBuilder: (context, index) {
                                          final batch = filtered[index];
                                          final productName =
                                              batch.productId != null
                                              ? cachedProductMap[batch
                                                    .productId]
                                              : null;
                                          return _BatchCard(
                                            title:
                                                'Batch #${batch.id}: ${productName ?? batch.displayProduct}',
                                            subtitle:
                                                '${batch.quantity} ${batch.unit}',
                                            status: batch.status,
                                            trailing: const Icon(
                                              Icons.chevron_right,
                                            ),
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      BatchDetailPage(
                                                        batchId: batch.id,
                                                      ),
                                                ),
                                              );
                                            },
                                          );
                                        },
                                      );
                                    }
                                    return Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Text('Failed to load batches'),
                                          const SizedBox(height: 8),
                                          ElevatedButton(
                                            onPressed: () => ref.invalidate(
                                              ownedBatchListProvider,
                                            ),
                                            child: const Text('Retry'),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),

                          // Tab 2: Outgoing Pending Requests
                          outboxAsync.when(
                            data: (requests) {
                              final pending = requests
                                  .where((item) => item.status == 'PENDING')
                                  .toList();
                              final filteredPending = _filterRequests(
                                pending,
                                searchQuery,
                              );
                              if (filteredPending.isEmpty) {
                                return RefreshIndicator(
                                  onRefresh: () async {
                                    ref.invalidate(ownershipOutboxProvider);
                                    await ref.read(
                                      ownershipOutboxProvider.future,
                                    );
                                  },
                                  child: ListView(
                                    physics:
                                        const AlwaysScrollableScrollPhysics(),
                                    children: const [
                                      SizedBox(height: 80),
                                      EmptyState(
                                        icon: Icons.outbox_outlined,
                                        title: 'Outbox is empty',
                                        message:
                                            'No pending purchase requests.',
                                      ),
                                    ],
                                  ),
                                );
                              }
                              return RefreshIndicator(
                                onRefresh: () async {
                                  ref.invalidate(ownershipOutboxProvider);
                                  await ref.read(
                                    ownershipOutboxProvider.future,
                                  );
                                },
                                child: ListView.separated(
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    12,
                                    16,
                                    80,
                                  ),
                                  itemCount: filteredPending.length,
                                  separatorBuilder: (context, _) =>
                                      const SizedBox(height: 10),
                                  itemBuilder: (context, index) {
                                    final request = filteredPending[index];
                                    return Consumer(
                                      builder: (context, ref, _) {
                                        final batchAsync = ref.watch(
                                          batchByIdProvider(request.batchId),
                                        );
                                        final products = ref
                                            .watch(productListProvider)
                                            .value;
                                        final productMap = {
                                          for (final product in products ?? [])
                                            product.id: product.name,
                                        };
                                        final batch = batchAsync.value;
                                        final productName =
                                            batch?.productId != null
                                            ? productMap[batch!.productId]
                                            : null;
                                        return _BatchCard(
                                          title:
                                              'Batch #${request.batchId}: ${productName ?? batch?.displayProduct ?? 'Product'}',
                                          subtitle:
                                              'Requested: ${request.quantity} ${batch?.unit ?? 'kg'}',
                                          status: request.status,
                                          trailing: const Icon(
                                            Icons.chevron_right,
                                          ),
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => BatchDetailPage(
                                                  batchId: request.batchId,
                                                ),
                                              ),
                                            );
                                          },
                                        );
                                      },
                                    );
                                  },
                                ),
                              );
                            },
                            loading: () => const Center(
                              child: CircularProgressIndicator(),
                            ),
                            error: (_, _) {
                              if (cachedOutbox.isNotEmpty) {
                                final pending = cachedOutbox
                                    .where((item) => item.status == 'PENDING')
                                    .toList();
                                final filteredPending = _filterRequests(
                                  pending,
                                  searchQuery,
                                );
                                return ListView.separated(
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    12,
                                    16,
                                    80,
                                  ),
                                  itemCount: filteredPending.length,
                                  separatorBuilder: (context, _) =>
                                      const SizedBox(height: 10),
                                  itemBuilder: (context, index) {
                                    final request = filteredPending[index];
                                    return _BatchCard(
                                      title: 'Batch #${request.batchId}',
                                      subtitle:
                                          'Requested: ${request.quantity}',
                                      status: request.status,
                                      trailing: const Icon(Icons.chevron_right),
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => BatchDetailPage(
                                              batchId: request.batchId,
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                );
                              }
                              return Center(
                                child: TextButton(
                                  onPressed: () =>
                                      ref.invalidate(ownershipOutboxProvider),
                                  child: const Text('Retry'),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
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

class _BatchCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? status;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _BatchCard({
    required this.title,
    required this.subtitle,
    this.status,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(Gap.md + 2),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: c.primaryContainer,
              borderRadius: Radii.mdAll,
            ),
            child: Icon(
              Icons.inventory_2_rounded,
              color: c.onPrimaryContainer,
              size: 22,
            ),
          ),
          const SizedBox(width: Gap.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: c.onSurfaceVariant),
                ),
              ],
            ),
          ),
          if (status != null) ...[
            const SizedBox(width: Gap.sm),
            StatusPill(status),
          ],
          if (trailing != null) ...[const SizedBox(width: Gap.sm), trailing!],
        ],
      ),
    );
  }
}
