import 'package:flutter/material.dart';

class BatchHistoryTimeline extends StatelessWidget {
  const BatchHistoryTimeline({super.key});

  @override
  Widget build(BuildContext context) {
    final events = [
      'Batch created',
      'Grade A assigned',
      'Quantity adjusted',
      'Transferred to warehouse',
    ];

    return ListView.separated(
      itemCount: events.length,
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: (context, index) {
        return ListTile(
          leading: CircleAvatar(
            radius: 10,
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
          title: Text(events[index]),
          subtitle: Text('Event ${index + 1}'),
        );
      },
    );
  }
}
