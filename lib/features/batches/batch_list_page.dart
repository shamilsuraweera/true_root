import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
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
    if (query.trim().isEmpty) return items;
    final normalized = query.toLowerCase();
    final digits = query.replaceAll(RegExp(r'\D'), '');
    final queryId = int.tryParse(digits);
    return items.where((batch) {
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final headerBackground = isDark ? colorScheme.surface : AppColors.primary;
    final contentBackground = isDark
        ? theme.scaffoldBackgroundColor
        : AppColors.background;
    final headerIconBackground = isDark
        ? colorScheme.onSurface.withValues(alpha: 0.12)
        : Colors.white.withValues(alpha: 0.2);
    final headerTitleColor = isDark ? colorScheme.onSurface : Colors.white;
    final headerSubtitleColor = isDark
        ? colorScheme.onSurface.withValues(alpha: 0.82)
        : Colors.white.withValues(alpha: 0.9);

    final batchesAsync = ref.watch(ownedBatchListProvider);
    final productsAsync = ref.watch(productListProvider);
    final searchQuery = ref.watch(batchSearchProvider);
    final cachedOwnedBatches = ref.watch(cachedOwnedBatchListProvider);
    final cachedOutbox = ref.watch(cachedOwnershipOutboxProvider);
    final Map<int, String> cachedProductMap = {
      for (final product in productsAsync.valueOrNull ?? [])
        product.id: product.name,
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
        backgroundColor: headerBackground,
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CreateBatchPage()),
            );
          },
          child: const Icon(Icons.add),
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
                        child: _AppSearchField(
                          hintText: 'Search batches',
                          controller: _searchController,
                          onChanged: _handleSearchChanged,
                          useLightStyle: !isDark,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Material(
                        color: headerIconBackground,
                        shape: const CircleBorder(),
                        child: IconButton(
                          icon: Icon(
                            Icons.qr_code_scanner,
                            color: headerTitleColor,
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const QrScanPage(),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Material(
                        color: headerIconBackground,
                        shape: const CircleBorder(),
                        child: IconButton(
                          icon: Icon(
                            Icons.notifications_none,
                            color: headerTitleColor,
                          ),
                          onPressed: () {
                            showNotificationsSheet(context, ref);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Track your lot flow',
                    style: TextStyle(
                      color: headerTitleColor,
                      fontSize: 23,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Monitor owned batches and outgoing requests in one stream.',
                    style: TextStyle(color: headerSubtitleColor, fontSize: 14),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: contentBackground,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                ),
                child: Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(12, 12, 12, 4),
                      child: TabBar(
                        tabs: [
                          Tab(text: 'Owned'),
                          Tab(text: 'Pending'),
                        ],
                      ),
                    ),
                    Expanded(
                      child: TabBarView(
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
                                    physics:
                                        const AlwaysScrollableScrollPhysics(),
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
                                    for (final product in products)
                                      product.id: product.name,
                                  };
                                  final filteredBatches = _filterBatches(
                                    batches,
                                    productMap,
                                    searchQuery,
                                  );
                                  final emptyBatchMessage = searchQuery.isEmpty
                                      ? 'No batches yet'
                                      : 'No matching batches';
                                  if (filteredBatches.isEmpty) {
                                    return RefreshIndicator(
                                      onRefresh: () async {
                                        ref.invalidate(ownedBatchListProvider);
                                        ref.invalidate(productListProvider);
                                        await Future.wait([
                                          ref.read(
                                            ownedBatchListProvider.future,
                                          ),
                                          ref.read(productListProvider.future),
                                        ]);
                                      },
                                      child: ListView(
                                        physics:
                                            const AlwaysScrollableScrollPhysics(),
                                        children: [
                                          const SizedBox(height: 200),
                                          Center(
                                            child: Text(emptyBatchMessage),
                                          ),
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
                                      padding: const EdgeInsets.fromLTRB(
                                        16,
                                        12,
                                        16,
                                        24,
                                      ),
                                      itemCount: filteredBatches.length,
                                      separatorBuilder: (context, _) =>
                                          const SizedBox(height: 12),
                                      itemBuilder: (context, index) {
                                        final batch = filteredBatches[index];
                                        final productName =
                                            batch.productId != null
                                            ? productMap[batch.productId]
                                            : null;
                                        return _BatchCard(
                                          title:
                                              'Batch ${batch.id} • ${productName ?? batch.displayProduct}',
                                          subtitle:
                                              '${batch.quantity} ${batch.unit} • ${batch.status}',
                                          trailing: const Icon(
                                            Icons.chevron_right,
                                          ),
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => BatchDetailPage(
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
                                    24,
                                  ),
                                  itemCount: filtered.length,
                                  separatorBuilder: (context, _) =>
                                      const SizedBox(height: 12),
                                  itemBuilder: (context, index) {
                                    final batch = filtered[index];
                                    final productName = batch.productId != null
                                        ? cachedProductMap[batch.productId]
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
                                            builder: (_) => BatchDetailPage(
                                              batchId: batch.id,
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  },
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
                                child: ListView(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  children: [
                                    const SizedBox(height: 200),
                                    const Center(
                                      child: Text('Failed to load batches'),
                                    ),
                                    TextButton(
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
                          outboxAsync.when(
                            data: (requests) {
                              final pending = requests
                                  .where((item) => item.status == 'PENDING')
                                  .toList();
                              final filteredPending = _filterRequests(
                                pending,
                                searchQuery,
                              );
                              final emptyPendingMessage = searchQuery.isEmpty
                                  ? 'No pending requests'
                                  : 'No matching requests';
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
                                  await ref.read(
                                    ownershipOutboxProvider.future,
                                  );
                                },
                                child: ListView.separated(
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    12,
                                    16,
                                    24,
                                  ),
                                  itemCount: filteredPending.length,
                                  separatorBuilder: (context, _) =>
                                      const SizedBox(height: 12),
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
                                        final productName =
                                            batch?.productId != null
                                            ? productMap[batch!.productId]
                                            : null;
                                        return _BatchCard(
                                          title:
                                              'Batch ${request.batchId} • ${productName ?? batch?.displayProduct ?? 'Product'}',
                                          subtitle:
                                              '${request.quantity} ${batch?.unit ?? 'kg'} • ${batch?.status ?? request.status}',
                                          trailing: _StatusPill(
                                            label: request.status,
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
                                    24,
                                  ),
                                  itemCount: filteredPending.length,
                                  separatorBuilder: (context, _) =>
                                      const SizedBox(height: 12),
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
                                        final productName =
                                            batch?.productId != null
                                            ? productMap[batch!.productId]
                                            : null;
                                        return _BatchCard(
                                          title:
                                              'Batch ${request.batchId} • ${productName ?? batch?.displayProduct ?? 'Product'}',
                                          subtitle:
                                              '${request.quantity} ${batch?.unit ?? 'kg'} • ${batch?.status ?? request.status}',
                                          trailing: _StatusPill(
                                            label: request.status,
                                          ),
                                        );
                                      },
                                    );
                                  },
                                );
                              }
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
                                  children: [
                                    const SizedBox(height: 200),
                                    const Center(
                                      child: Text('Failed to load requests'),
                                    ),
                                    TextButton(
                                      onPressed: () => ref.invalidate(
                                        ownershipOutboxProvider,
                                      ),
                                      child: const Text('Retry'),
                                    ),
                                  ],
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

class _AppSearchField extends StatelessWidget {
  final String hintText;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final bool useLightStyle;

  const _AppSearchField({
    required this.hintText,
    this.controller,
    this.onChanged,
    this.useLightStyle = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hintText,
          prefixIcon: Icon(
            Icons.search,
            color: useLightStyle ? Colors.white.withValues(alpha: 0.9) : null,
          ),
          filled: true,
          fillColor: useLightStyle
              ? Colors.white.withValues(alpha: 0.18)
              : Theme.of(context).colorScheme.surface,
          hintStyle: useLightStyle
              ? TextStyle(color: Colors.white.withValues(alpha: 0.85))
              : null,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(999),
            borderSide: BorderSide(
              color: useLightStyle
                  ? Colors.white.withValues(alpha: 0.25)
                  : Theme.of(context).colorScheme.outline,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(999),
            borderSide: BorderSide(
              color: useLightStyle
                  ? Colors.white.withValues(alpha: 0.25)
                  : Theme.of(context).colorScheme.outline,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(999),
            borderSide: BorderSide(
              color: useLightStyle
                  ? Colors.white
                  : Theme.of(context).colorScheme.primary,
              width: 1.4,
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
