import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
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
    final products = ref.watch(productListProvider).valueOrNull;
    final Map<int, String> productMap = {
      for (final product in products ?? []) product.id: product.name,
    };

    final topInset = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: headerBackground,
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16, topInset + 12, 16, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _AppSearchField(
                        hintText: 'Search batches, requests, or activity...',
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
                          Icons.notifications_none,
                          color: headerTitleColor,
                        ),
                        tooltip: 'Notifications',
                        onPressed: () {
                          showNotificationsSheet(context, ref);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  'Supply Chain Overview',
                  style: TextStyle(
                    color: headerTitleColor,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Trace agricultural lots from farm to export in real-time.',
                  style: TextStyle(color: headerSubtitleColor, fontSize: 13),
                ),
                const SizedBox(height: 14),
                // Top KPI summary chips
                Row(
                  children: [
                    Expanded(
                      child: _KpiMiniCard(
                        label: 'Active Batches',
                        value: '${batchesAsync.valueOrNull?.length ?? 0}',
                        icon: Icons.inventory_2_outlined,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _KpiMiniCard(
                        label: 'Pending Inbound',
                        value: '${requestsAsync.valueOrNull?.where((r) => r.status == 'PENDING').length ?? 0}',
                        icon: Icons.inbox_outlined,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: contentBackground,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),
              child: RefreshIndicator(
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
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
                  children: [
                    _SectionCard(
                      title: 'Purchase & Transfer Requests',
                      actionLabel: 'View all',
                      onAction: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RequestsPage(),
                          ),
                        );
                      },
                      child: requestsAsync.when(
                        data: (items) {
                          final pending = items
                              .where((item) => item.status == 'PENDING')
                              .toList();
                          final filtered = _filterRequests(
                            pending,
                            searchQuery,
                          );
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
                                            builder: (_) => BatchDetailPage(batchId: item.batchId),
                                          ),
                                        );
                                      },
                                      onReject: () =>
                                          _rejectRequest(context, ref, item.id),
                                      onApprove: () => _approveRequest(
                                        context,
                                        ref,
                                        item.id,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          );
                        },
                        loading: () => const _LoadingState(),
                        error: (_, _) {
                          final fallback = _filterRequests(
                            cachedRequests
                                .where((item) => item.status == 'PENDING')
                                .toList(),
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
                                            builder: (_) => BatchDetailPage(batchId: item.batchId),
                                          ),
                                        );
                                      },
                                      onReject: () =>
                                          _rejectRequest(context, ref, item.id),
                                      onApprove: () => _approveRequest(
                                        context,
                                        ref,
                                        item.id,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }
                          return _ErrorState(
                            message: 'Failed to load requests',
                            onRetry: () =>
                                ref.invalidate(pendingRequestsProvider),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    _SectionCard(
                      title: 'My Batches & Lots',
                      actionLabel: 'View all',
                      onAction: () {
                        ref.read(dashboardTabProvider.notifier).state = 1;
                      },
                      child: batchesAsync.when(
                        data: (items) {
                          final filtered = _filterBatches(
                            items,
                            searchQuery,
                            productMap,
                          );
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
                                    subtitle: '${item.quantity} ${item.unit} • ${item.grade ?? 'Standard'}',
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
                            onRetry: () =>
                                ref.invalidate(recentBatchesProvider),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    _SectionCard(
                      title: 'Recent Activity',
                      actionLabel: 'View all',
                      onAction: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ActivityPage(),
                          ),
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
                                  (item) => _ActivityTile(
                                    title: item.title,
                                    subtitle: item.subtitle,
                                  ),
                                )
                                .toList(),
                          );
                        },
                        loading: () => const _LoadingState(),
                        error: (_, _) {
                          final fallback = _filterActivity(
                            cachedActivity,
                            searchQuery,
                          );
                          if (fallback.isNotEmpty) {
                            return Column(
                              children: [
                                const _OfflineNote(),
                                ...fallback.map(
                                  (item) => _ActivityTile(
                                    title: item.title,
                                    subtitle: item.subtitle,
                                  ),
                                ),
                              ],
                            );
                          }
                          return _ErrorState(
                            message: 'Failed to load activity',
                            onRetry: () =>
                                ref.invalidate(recentActivityProvider),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _KpiMiniCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _KpiMiniCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                label,
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
            ],
          ),
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
    return Card(
      elevation: 0.8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                TextButton(
                  onPressed: onAction,
                  child: Text(actionLabel),
                ),
              ],
            ),
            const SizedBox(height: 8),
            child,
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
      height: 42,
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
              ? TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13)
              : const TextStyle(fontSize: 13),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
              color: useLightStyle ? Colors.white : Theme.of(context).colorScheme.primary,
              width: 1.4,
            ),
          ),
        ),
        onChanged: onChanged,
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
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey),
                ],
              ),
              const SizedBox(height: 4),
              Text('$batchId • $quantity', style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red.shade700,
                        side: BorderSide(color: Colors.red.shade200),
                      ),
                      onPressed: onReject,
                      child: const Text('Reject'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        foregroundColor: Colors.white,
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
  final batch = batchAsync.valueOrNull;
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
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.2)),
      ),
      child: ListTile(
        dense: true,
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.inventory_2_outlined, color: AppColors.primary, size: 18),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
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
      leading: const Icon(
        Icons.check_circle_outline,
        color: AppColors.secondary,
        size: 20,
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const _ErrorState({required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message, style: Theme.of(context).textTheme.bodyMedium),
          if (onRetry != null)
            TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;

  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Text(message, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
      ),
    );
  }
}

class _OfflineNote extends StatelessWidget {
  const _OfflineNote();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        'Offline: showing cached data',
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;

  const _StatusChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final color = AppColors.statusColor(label);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
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
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32)),
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
    ref.read(notificationsProvider.notifier).add(
          title: 'Request Approved',
          message: 'Purchase request #$requestId has been approved and transferred.',
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
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
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
    ref.read(notificationsProvider.notifier).add(
          title: 'Request Rejected',
          message: 'Purchase request #$requestId has been rejected.',
        );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Request rejected')),
    );
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
