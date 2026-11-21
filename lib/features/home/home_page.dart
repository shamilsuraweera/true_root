import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/app_widgets.dart';
import '../../core/widgets/brand_logo.dart';
import 'state/dashboard_provider.dart';
import '../products/state/product_provider.dart';
import '../requests/requests_page.dart';
import '../dashboard/state/dashboard_tab_provider.dart';
import '../activity/activity_page.dart';
import '../requests/state/ownership_requests_provider.dart';
import '../batches/state/batch_provider.dart';
import '../batches/models/batch.dart';
import '../batches/batch_detail_page.dart';
import '../requests/models/ownership_request.dart';
import 'models/recent_activity.dart';
import '../notifications/notifications_sheet.dart';
import '../notifications/notifications_provider.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: ref.read(dashboardSearchProvider),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleSearchChanged(String value) {
    ref.read(dashboardSearchProvider.notifier).state = value;
  }

  List<OwnershipRequest> _filterRequests(
    List<OwnershipRequest> items,
    String query,
  ) {
    if (query.isEmpty) return items;
    final normalized = query.toLowerCase();
    return items.where((request) {
      final text = [
        request.batchId,
        request.requesterId,
        request.status,
        request.note ?? '',
        request.quantity.toString(),
      ].join(' ').toLowerCase();
      return text.contains(normalized);
    }).toList();
  }

  List<Batch> _filterBatches(
    List<Batch> items,
    String query,
    Map<int, String> productMap,
  ) {
    if (query.isEmpty) return items;
    final normalized = query.toLowerCase();
    return items.where((batch) {
      final productName =
          productMap[batch.productId ?? -1] ?? batch.displayProduct;
      final text =
          'Batch ${batch.id} $productName ${batch.status} ${batch.ownerName ?? ''}'
              .toLowerCase();
      return text.contains(normalized);
    }).toList();
  }

  List<RecentActivity> _filterActivity(
    List<RecentActivity> items,
    String query,
  ) {
    if (query.isEmpty) return items;
    final normalized = query.toLowerCase();
    return items.where((activity) {
      final text = '${activity.title} ${activity.subtitle}'.toLowerCase();
      return text.contains(normalized);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final searchQuery = ref.watch(dashboardSearchProvider);
    if (_searchController.text != searchQuery) {
      _searchController.value = TextEditingValue(
        text: searchQuery,
        selection: TextSelection.collapsed(offset: searchQuery.length),
      );
    }
    final requestsAsync = ref.watch(pendingRequestsProvider);
    final batchesAsync = ref.watch(recentBatchesProvider);
    final activityAsync = ref.watch(recentActivityProvider);
    final cachedRequests = ref.watch(cachedPendingRequestsProvider);
    final cachedBatches = ref.watch(cachedRecentBatchesProvider);
    final cachedActivity = ref.watch(cachedRecentActivityProvider);
    final products = ref.watch(productListProvider).value;
    final Map<int, String> productMap = {
      for (final product in products ?? []) product.id: product.name,
    };

    final width = MediaQuery.sizeOf(context).width;
    final twoCol = width >= 1000;
    final pendingCount =
        requestsAsync.value?.where((r) => r.status == 'PENDING').length ?? 0;
    final batchCount = batchesAsync.value?.length ?? 0;

    final requestsSection = _SectionCard(
      title: 'Purchase & Transfer Requests',
      actionLabel: 'View all',
      onAction: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const RequestsPage()),
        );
      },
      child: requestsAsync.when(
        data: (items) {
          final pending = items
              .where((item) => item.status == 'PENDING')
              .toList();
          final filtered = _filterRequests(pending, searchQuery);
          final emptyMessage = searchQuery.isEmpty
              ? 'No pending purchase requests'
              : 'No matching requests';
          if (filtered.isEmpty) {
            return _EmptyState(message: emptyMessage);
          }
          return Column(
            children: filtered
                .map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _RequestCard(
                      name: 'Requester ID #${item.requesterId}',
                      batchId: 'Batch #${item.batchId}',
                      quantity: _requestQuantityText(ref, item),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                BatchDetailPage(batchId: item.batchId),
                          ),
                        );
                      },
                      onReject: () => _rejectRequest(context, ref, item.id),
                      onApprove: () => _approveRequest(context, ref, item.id),
                    ),
                  ),
                )
                .toList(),
          );
        },
        loading: () => const _LoadingState(),
        error: (_, _) {
          final fallback = _filterRequests(
            cachedRequests.where((item) => item.status == 'PENDING').toList(),
            searchQuery,
          );
          if (fallback.isNotEmpty) {
            return Column(
              children: [
                const _OfflineNote(),
                ...fallback.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _RequestCard(
                      name: 'Requester ID #${item.requesterId}',
                      batchId: 'Batch #${item.batchId}',
                      quantity: _requestQuantityText(ref, item),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                BatchDetailPage(batchId: item.batchId),
                          ),
                        );
                      },
                      onReject: () => _rejectRequest(context, ref, item.id),
                      onApprove: () => _approveRequest(context, ref, item.id),
                    ),
                  ),
                ),
              ],
            );
          }
          return _ErrorState(
            message: 'Failed to load requests',
            onRetry: () => ref.invalidate(pendingRequestsProvider),
          );
        },
      ),
    );
    final batchesSection = _SectionCard(
      title: 'My Batches & Lots',
      actionLabel: 'View all',
      onAction: () {
        ref.read(dashboardTabProvider.notifier).state = 1;
      },
      child: batchesAsync.when(
        data: (items) {
          final filtered = _filterBatches(items, searchQuery, productMap);
          final emptyMessage = searchQuery.isEmpty
              ? 'No batches in your inventory'
              : 'No matching batches';
          if (filtered.isEmpty) {
            return _EmptyState(message: emptyMessage);
          }
          return Column(
            children: filtered
                .map(
                  (item) => _InfoTile(
                    title:
                        'Batch #${item.id}: ${productMap[item.productId] ?? item.displayProduct}',
                    subtitle:
                        '${item.quantity} ${item.unit} • ${item.grade ?? 'Standard'}',
                    trailing: _StatusChip(label: item.status),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BatchDetailPage(batchId: item.id),
                        ),
                      );
                    },
                  ),
                )
                .toList(),
          );
        },
        loading: () => const _LoadingState(),
        error: (_, _) {
          final fallback = _filterBatches(
            cachedBatches,
            searchQuery,
            productMap,
          );
          if (fallback.isNotEmpty) {
            return Column(
              children: [
                const _OfflineNote(),
                ...fallback.map(
                  (item) => _InfoTile(
                    title:
                        'Batch #${item.id}: ${productMap[item.productId] ?? item.displayProduct}',
                    subtitle: '${item.quantity} ${item.unit}',
                    trailing: _StatusChip(label: item.status),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BatchDetailPage(batchId: item.id),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          }
          return _ErrorState(
            message: 'Failed to load batches',
            onRetry: () => ref.invalidate(recentBatchesProvider),
          );
        },
      ),
    );
    final activitySection = _SectionCard(
      title: 'Recent Activity',
      actionLabel: 'View all',
      onAction: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ActivityPage()),
        );
      },
      child: activityAsync.when(
        data: (items) {
          final filtered = _filterActivity(items, searchQuery);
          final emptyMessage = searchQuery.isEmpty
              ? 'No recent activity recorded'
              : 'No matching activity';
          if (filtered.isEmpty) {
            return _EmptyState(message: emptyMessage);
          }
          return Column(
            children: filtered
                .map(
                  (item) =>
                      _ActivityTile(title: item.title, subtitle: item.subtitle),
                )
                .toList(),
          );
        },
        loading: () => const _LoadingState(),
        error: (_, _) {
          final fallback = _filterActivity(cachedActivity, searchQuery);
          if (fallback.isNotEmpty) {
            return Column(
              children: [
                const _OfflineNote(),
                ...fallback.map(
                  (item) =>
                      _ActivityTile(title: item.title, subtitle: item.subtitle),
                ),
              ],
            );
          }
          return _ErrorState(
            message: 'Failed to load activity',
            onRetry: () => ref.invalidate(recentActivityProvider),
          );
        },
      ),
    );

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(pendingRequestsProvider);
          ref.invalidate(recentBatchesProvider);
          ref.invalidate(recentActivityProvider);
          ref.invalidate(productListProvider);
          await Future.wait([
            ref.read(pendingRequestsProvider.future),
            ref.read(recentBatchesProvider.future),
            ref.read(recentActivityProvider.future),
          ]);
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            Gap.lg,
            MediaQuery.paddingOf(context).top + Gap.lg,
            Gap.lg,
            width < Breakpoints.tablet ? 120 : Gap.xxl,
          ),
          children: [
            ContentWidth(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FadeSlideIn(
                    child: Row(
                      children: [
                        Expanded(
                          child: AppSearchField(
                            hint: 'Search batches, requests, or activity...',
                            controller: _searchController,
                            onChanged: _handleSearchChanged,
                          ),
                        ),
                        const SizedBox(width: Gap.md),
                        Badge(
                          isLabelVisible: pendingCount > 0,
                          label: Text('$pendingCount'),
                          child: IconButton.filledTonal(
                            icon: const Icon(Icons.notifications_none_rounded),
                            tooltip: 'Notifications',
                            onPressed: () =>
                                showNotificationsSheet(context, ref),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: Gap.xl),
                  FadeSlideIn(
                    index: 1,
                    child: _HeroBanner(
                      pending: pendingCount,
                      batches: batchCount,
                      onScan: () =>
                          ref.read(dashboardTabProvider.notifier).state = 1,
                    ),
                  ),
                  const SizedBox(height: Gap.xl),
                  FadeSlideIn(
                    index: 2,
                    child: Row(
                      children: [
                        Expanded(
                          child: KpiCard(
                            label: 'Active batches',
                            value: '$batchCount',
                            icon: Icons.inventory_2_rounded,
                          ),
                        ),
                        const SizedBox(width: Gap.md),
                        Expanded(
                          child: KpiCard(
                            label: 'Pending inbound',
                            value: '$pendingCount',
                            icon: Icons.inbox_rounded,
                            color: context.status.warning,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: Gap.xl),
                  if (twoCol)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: Column(
                            children: [
                              requestsSection,
                              const SizedBox(height: Gap.xl),
                              batchesSection,
                            ],
                          ),
                        ),
                        const SizedBox(width: Gap.xl),
                        Expanded(flex: 2, child: activitySection),
                      ],
                    )
                  else ...[
                    requestsSection,
                    const SizedBox(height: Gap.xl),
                    batchesSection,
                    const SizedBox(height: Gap.xl),
                    activitySection,
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner({
    required this.pending,
    required this.batches,
    required this.onScan,
  });
  final int pending;
  final int batches;
  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Gap.xl),
      decoration: BoxDecoration(
        gradient: AppGradients.brand,
        borderRadius: Radii.xlAll,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.28),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Supply Chain Overview',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: Gap.sm),
                Text(
                  pending > 0
                      ? 'You have $pending pending request${pending == 1 ? '' : 's'} waiting for review.'
                      : 'Trace agricultural lots from farm to export in real time.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.88),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: Gap.lg),
                FilledButton.icon(
                  onPressed: onScan,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primaryDark,
                    minimumSize: const Size(0, 44),
                  ),
                  icon: const Icon(Icons.inventory_2_rounded, size: 18),
                  label: const Text('View batches'),
                ),
              ],
            ),
          ),
          if (MediaQuery.sizeOf(context).width >= 420) ...[
            const SizedBox(width: Gap.lg),
            Opacity(
              opacity: 0.95,
              child: BrandLogo.mark(size: 92, light: true),
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String actionLabel;
  final VoidCallback onAction;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.actionLabel,
    required this.onAction,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(Gap.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title, action: actionLabel, onAction: onAction),
          child,
        ],
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final String name;
  final String batchId;
  final String quantity;
  final VoidCallback? onTap;
  final VoidCallback onReject;
  final VoidCallback onApprove;

  const _RequestCard({
    required this.name,
    required this.batchId,
    required this.quantity,
    this.onTap,
    required this.onReject,
    required this.onApprove,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(
        context,
      ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      shape: RoundedRectangleBorder(
        borderRadius: Radii.mdAll,
        side: BorderSide(color: Theme.of(context).colorScheme.outline),
      ),
      child: InkWell(
        borderRadius: Radii.mdAll,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(Gap.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '$batchId • $quantity',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: context.status.danger,
                        side: BorderSide(
                          color: context.status.danger.withValues(alpha: 0.4),
                        ),
                        minimumSize: const Size(0, 44),
                      ),
                      onPressed: onReject,
                      child: const Text('Reject'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.status.success,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 44),
                      ),
                      onPressed: onApprove,
                      child: const Text('Approve'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _requestQuantityText(WidgetRef ref, OwnershipRequest request) {
  final batchAsync = ref.watch(batchByIdProvider(request.batchId));
  final batch = batchAsync.value;
  final unit = batch?.unit ?? 'kg';
  return '${request.quantity} $unit';
}

class _InfoTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget trailing;
  final VoidCallback? onTap;

  const _InfoTile({
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: Gap.sm),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: Radii.mdAll,
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: Radii.mdAll),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: Radii.smAll,
          ),
          child: Icon(
            Icons.inventory_2_rounded,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
            size: 20,
          ),
        ),
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(subtitle),
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final String title;
  final String subtitle;

  const _ActivityTile({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        Icons.check_circle_rounded,
        color: context.status.success,
        size: 22,
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) => const Column(
    children: [
      Skeleton(height: 56, radius: 14),
      SizedBox(height: Gap.sm),
      Skeleton(height: 56, radius: 14),
    ],
  );
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const _ErrorState({required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) =>
      ErrorState(message: message, onRetry: onRetry);
}

class _EmptyState extends StatelessWidget {
  final String message;

  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) => EmptyState(title: message);
}

class _OfflineNote extends StatelessWidget {
  const _OfflineNote();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        'Offline: showing cached data',
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: context.status.warning),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;

  const _StatusChip({required this.label});

  @override
  Widget build(BuildContext context) => StatusPill(label);
}

Future<void> _approveRequest(
  BuildContext context,
  WidgetRef ref,
  String requestId,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Approve Purchase Request?'),
      content: const Text(
        'This will accept the request and transfer lot ownership to the requester.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: context.status.success,
          ),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Approve & Transfer'),
        ),
      ],
    ),
  );

  if (confirmed != true) return;

  try {
    final api = ref.read(ownershipRequestsApiProvider);
    await api.approve(requestId);
    _invalidateRequests(ref);
    ref
        .read(notificationsProvider.notifier)
        .add(
          title: 'Request Approved',
          message:
              'Purchase request #$requestId has been approved and transferred.',
        );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Request approved successfully')),
    );
  } catch (error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
    );
  }
}

Future<void> _rejectRequest(
  BuildContext context,
  WidgetRef ref,
  String requestId,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Reject Purchase Request?'),
      content: const Text(
        'Are you sure you want to decline this purchase request?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: context.status.danger,
          ),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Reject Request'),
        ),
      ],
    ),
  );

  if (confirmed != true) return;

  try {
    final api = ref.read(ownershipRequestsApiProvider);
    await api.reject(requestId);
    _invalidateRequests(ref);
    ref
        .read(notificationsProvider.notifier)
        .add(
          title: 'Request Rejected',
          message: 'Purchase request #$requestId has been rejected.',
        );
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Request rejected')));
  } catch (error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
    );
  }
}

void _invalidateRequests(WidgetRef ref) {
  ref.invalidate(pendingRequestsProvider);
  ref.invalidate(ownershipInboxProvider);
  ref.invalidate(ownershipOutboxProvider);
  ref.invalidate(ownedBatchListProvider);
  ref.invalidate(batchListProvider);
  ref.invalidate(recentBatchesProvider);
  ref.invalidate(recentActivityProvider);
}
