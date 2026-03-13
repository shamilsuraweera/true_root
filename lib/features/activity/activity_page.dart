import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../home/state/dashboard_provider.dart';

class ActivityPage extends ConsumerWidget {
  const ActivityPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activityAsync = ref.watch(recentActivityProvider);
    final cachedActivity = ref.watch(cachedRecentActivityProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Activity')),
      body: activityAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('No activity yet'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (context, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = items[index];
              return ListTile(
                leading: const Icon(Icons.check_circle_outline),
                title: Text(item.title),
                subtitle: Text(item.subtitle),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) {
          if (cachedActivity.isNotEmpty) {
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: cachedActivity.length,
              separatorBuilder: (context, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = cachedActivity[index];
                return ListTile(
                  leading: const Icon(Icons.check_circle_outline),
                  title: Text(item.title),
                  subtitle: Text(item.subtitle),
                );
              },
            );
          }
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Failed to load activity'),
                TextButton(
                  onPressed: () => ref.invalidate(recentActivityProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
