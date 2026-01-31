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
import '../requests/models/ownership_request.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(pendingRequestsProvider);
    final batchesAsync = ref.watch(recentBatchesProvider);
    final activityAsync = ref.watch(recentActivityProvider);
    final products = ref.watch(productListProvider).valueOrNull;
    final productMap = {
      for (final product in products ?? []) product.id: product.name,
    };

    return Scaffold(
      appBar: AppBar(
        title: const _AppSearchField(hintText: 'Search'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('No notifications')),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(pendingRequestsProvider);
          ref.invalidate(recentBatchesProvider);
          ref.invalidate(recentActivityProvider);
          await Future.wait([
            ref.read(pendingRequestsProvider.future),
            ref.read(recentBatchesProvider.future),
            ref.read(recentActivityProvider.future),
          ]);
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
          _SectionCard(
            title: 'Purchase Requests',
            actionLabel: 'View all',
            onAction: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RequestsPage()),
              );
            },
            child: requestsAsync.when(
              data: (items) {
                final pending = items.where((item) => item.status == 'PENDING').toList();
                if (pending.isEmpty) {
                  return const _EmptyState(message: 'No pending requests');
                }
                return Column(
                  children: pending
                      .map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _RequestCard(
                            name: 'Requester ${item.requesterId}',
                            batchId: 'Batch ${item.batchId}',
                            quantity: _requestQuantityText(ref, item),
                            onReject: () => _rejectRequest(context, ref, item.id),
                            onApprove: () => _approveRequest(context, ref, item.id),
                          ),
                        ),
                      )
                      .toList(),
                );
              },
              loading: () => const _LoadingState(),
              error: (_, _) => const _ErrorState(message: 'Failed to load requests'),
            ),
          ),
          const SizedBox(height: 24),
          _SectionCard(
            title: 'My Batches',
            actionLabel: 'View all',
            onAction: () {
              ref.read(dashboardTabProvider.notifier).state = 1;
            },
            child: batchesAsync.when(
              data: (items) {
                if (items.isEmpty) {
                  return const _EmptyState(message: 'No batches yet');
                }
                return Column(
                  children: items
                      .map(
                        (item) => _InfoTile(
                          title: 'Batch ${item.id} • ${productMap[item.productId] ?? item.displayProduct}',
                          subtitle: '${item.quantity} ${item.unit}',
                          trailing: _StatusChip(label: item.status),
                        ),
                      )
                      .toList(),
                );
              },
              loading: () => const _LoadingState(),
              error: (_, _) => const _ErrorState(message: 'Failed to load batches'),
            ),
          ),
          const SizedBox(height: 24),
          _SectionCard(
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
                if (items.isEmpty) {
                  return const _EmptyState(message: 'No recent activity');
                }
                return Column(
                  children: items
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
              error: (_, _) => const _ErrorState(message: 'Failed to load activity'),
            ),
          ),
          ],
        ),
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
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

  const _AppSearchField({required this.hintText});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: TextField(
        decoration: InputDecoration(
          hintText: hintText,
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surface,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(999),
            borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(999),
            borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
          ),
        ),
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final String name;
  final String batchId;
  final String quantity;
  final VoidCallback onReject;
  final VoidCallback onApprove;

  const _RequestCard({
    required this.name,
    required this.batchId,
    required this.quantity,
    required this.onReject,
    required this.onApprove,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.accent.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 4),
            Text('$batchId • $quantity'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onReject,
                    child: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onApprove,
                    child: const Text('Approve'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String _requestQuantityText(WidgetRef ref, OwnershipRequest request) {
  final batchAsync = ref.watch(batchByIdProvider(request.batchId));
  final products = ref.watch(productListProvider).valueOrNull;
  final productMap = {
    for (final product in products ?? []) product.id: product.name,
  };
  final batch = batchAsync.valueOrNull;
  final productName = batch?.productId != null ? productMap[batch!.productId] : null;
  final unit = batch?.unit ?? 'kg';
  if (productName != null) {
    return '${request.quantity} $unit • $productName';
  }
  return '${request.quantity} $unit';
}

class _InfoTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget trailing;

  const _InfoTile({
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: trailing,
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final String title;
  final String subtitle;

  const _ActivityTile({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.check_circle_outline, color: AppColors.secondary),
      title: Text(title),
      subtitle: Text(subtitle),
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

  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(message, style: Theme.of(context).textTheme.bodyMedium),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;

  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(message, style: Theme.of(context).textTheme.bodyMedium),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;

  const _StatusChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: onSurface.withValues(alpha: 0.75),
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

Future<void> _approveRequest(BuildContext context, WidgetRef ref, String requestId) async {
  try {
    final api = ref.read(ownershipRequestsApiProvider);
    await api.approve(requestId);
    _invalidateRequests(ref);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Request approved')),
    );
  } catch (error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
    );
  }
}

Future<void> _rejectRequest(BuildContext context, WidgetRef ref, String requestId) async {
  try {
    final api = ref.read(ownershipRequestsApiProvider);
    await api.reject(requestId);
    _invalidateRequests(ref);
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
