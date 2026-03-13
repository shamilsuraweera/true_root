import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'notifications_provider.dart';

void showNotificationsSheet(BuildContext context, WidgetRef ref) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (_) => const _NotificationsSheet(),
  );
}

class _NotificationsSheet extends ConsumerWidget {
  const _NotificationsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationsProvider);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Notifications', style: Theme.of(context).textTheme.titleMedium),
                if (notifications.isNotEmpty)
                  TextButton(
                    onPressed: () => ref.read(notificationsProvider.notifier).clear(),
                    child: const Text('Clear all'),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (notifications.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('No notifications'),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: notifications.length,
                  separatorBuilder: (context, _) => const Divider(height: 16),
                  itemBuilder: (context, index) {
                    final item = notifications[index];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.title, style: Theme.of(context).textTheme.titleSmall),
                        const SizedBox(height: 4),
                        Text(item.message),
                      ],
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
