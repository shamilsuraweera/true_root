import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'state/batch_provider.dart';

class BatchHistoryTimeline extends ConsumerWidget {
  final String batchId;

  const BatchHistoryTimeline({super.key, required this.batchId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(batchHistoryProvider(batchId));

    return historyAsync.when(
      data: (events) {
        if (events.isEmpty) {
          return const Center(child: Text('No history yet'));
        }
        return ListView.separated(
          itemCount: events.length,
          separatorBuilder: (context, index) => const Divider(),
          itemBuilder: (context, index) {
            final event = events[index];
            return ListTile(
              leading: CircleAvatar(
                radius: 10,
                backgroundColor: Theme.of(context).colorScheme.primary,
              ),
              title: Text(event.type),
              subtitle: Text(event.description ?? event.createdAt),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => const Center(child: Text('Failed to load history')),
    );
  }
}
