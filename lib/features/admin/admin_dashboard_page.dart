import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../home/models/recent_activity.dart';
import 'state/admin_provider.dart';

class AdminDashboardPage extends ConsumerWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overviewAsync = ref.watch(adminOverviewProvider);
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(adminOverviewProvider);
        await ref.read(adminOverviewProvider.future);
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          Text('Overview', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          overviewAsync.when(
            data: (overview) {
              return Column(
                children: [
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      _MetricCard(label: 'Users', value: overview.users.toString()),
                      _MetricCard(label: 'Products', value: overview.products.toString()),
                      _MetricCard(label: 'Stages', value: overview.stages.toString()),
                      _MetricCard(label: 'Batches', value: overview.batches.toString()),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _SectionTitle(title: 'Recent Activity'),
                  const SizedBox(height: 12),
                  if (overview.recentActivity.isEmpty)
                    const Text('No recent activity')
                  else
                    Column(
                      children: overview.recentActivity
                          .map((item) => _ActivityRow(activity: item))
                          .toList(),
                    ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => const Text('Failed to load overview'),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;

  const _MetricCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: 8),
              Text(value, style: Theme.of(context).textTheme.headlineSmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(title, style: Theme.of(context).textTheme.titleMedium);
  }
}

class _ActivityRow extends StatelessWidget {
  final RecentActivity activity;

  const _ActivityRow({required this.activity});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.check_circle_outline),
        title: Text(activity.title),
        subtitle: Text(activity.subtitle),
      ),
    );
  }
}
