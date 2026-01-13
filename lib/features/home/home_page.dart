import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import 'state/dashboard_provider.dart';
import '../products/state/product_provider.dart';

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
      appBar: AppBar(title: const Text('Dashboard')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionHeader(
            title: 'Purchase Requests',
            action: TextButton(
              onPressed: () {},
              child: const Text('View all'),
            ),
          ),
          const SizedBox(height: 8),
          requestsAsync.when(
            data: (items) {
              if (items.isEmpty) {
                return const _EmptyState(message: 'No pending requests');
              }
              return Column(
                children: items
                    .map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _RequestCard(
                          name: item.requesterName,
                          batchId: 'Batch ${item.batchId}',
                          quantity: item.quantity,
                        ),
                      ),
                    )
                    .toList(),
              );
            },
            loading: () => const _LoadingState(),
            error: (_, _) => const _ErrorState(message: 'Failed to load requests'),
          ),
          const SizedBox(height: 24),
          _SectionHeader(
            title: 'My Batches',
            action: TextButton(
              onPressed: () {},
              child: const Text('View all'),
            ),
          ),
          const SizedBox(height: 8),
          batchesAsync.when(
            data: (items) {
              if (items.isEmpty) {
                return const _EmptyState(message: 'No batches yet');
              }
              return Column(
                children: items
                    .map(
                      (item) => _InfoTile(
                        title: productMap[item.productId] ?? item.displayProduct,
                        subtitle: 'Batch ${item.id} • ${item.quantity} ${item.unit}',
                        trailing: _StatusChip(label: item.status),
                      ),
                    )
                    .toList(),
              );
            },
            loading: () => const _LoadingState(),
            error: (_, _) => const _ErrorState(message: 'Failed to load batches'),
          ),
          const SizedBox(height: 24),
          _SectionHeader(
            title: 'Recent Activity',
            action: TextButton(
              onPressed: () {},
              child: const Text('View all'),
            ),
          ),
          const SizedBox(height: 8),
          activityAsync.when(
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
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final Widget action;

  const _SectionHeader({required this.title, required this.action});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        action,
      ],
    );
  }
}

class _RequestCard extends StatelessWidget {
  final String name;
  final String batchId;
  final String quantity;

  const _RequestCard({
    required this.name,
    required this.batchId,
    required this.quantity,
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
                    onPressed: () {},
                    child: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {},
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.textDark,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
