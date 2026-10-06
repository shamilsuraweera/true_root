import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import 'state/batch_provider.dart';
import 'models/batch_event.dart';

class BatchHistoryTimeline extends ConsumerWidget {
  final String batchId;

  const BatchHistoryTimeline({super.key, required this.batchId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(batchHistoryProvider(batchId));

    return historyAsync.when(
      data: (events) {
        if (events.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.history_toggle_off, size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 8),
                  Text(
                    'No timeline events yet',
                    style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: events.length,
          itemBuilder: (context, index) {
            final event = events[index];
            final isFirst = index == 0;
            final isLast = index == events.length - 1;
            return _TimelineItem(
              event: event,
              isFirst: isFirst,
              isLast: isLast,
            );
          },
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (err, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Failed to load history: $err', style: const TextStyle(color: Colors.red)),
        ),
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final BatchEvent event;
  final bool isFirst;
  final bool isLast;

  const _TimelineItem({
    required this.event,
    required this.isFirst,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final config = _getEventConfig(event.type);
    final local = event.createdAt.toLocal();
    final timeStr =
        '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')} '
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator line and icon
          SizedBox(
            width: 48,
            child: Column(
              children: [
                // Top line
                Container(
                  width: 2,
                  height: 12,
                  color: isFirst ? Colors.transparent : Colors.grey.shade300,
                ),
                // Icon circle
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: config.color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: config.color, width: 2),
                  ),
                  child: Icon(config.icon, size: 18, color: config.color),
                ),
                // Bottom line
                Expanded(
                  child: Container(
                    width: 2,
                    color: isLast ? Colors.transparent : Colors.grey.shade300,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Content Card
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.4)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        config.title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      Text(
                        timeStr,
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                  if (event.description != null && event.description!.trim().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      event.description!,
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  _EventConfig _getEventConfig(String type) {
    switch (type.toUpperCase()) {
      case 'CREATED':
        return _EventConfig(title: 'Batch Created', icon: Icons.add_circle, color: const Color(0xFF2E7D32));
      case 'SPLIT':
        return _EventConfig(title: 'Batch Split', icon: Icons.call_split, color: const Color(0xFF8E24AA));
      case 'MERGED':
        return _EventConfig(title: 'Batch Merged', icon: Icons.merge_type, color: const Color(0xFFEF6C00));
      case 'TRANSFORMED':
        return _EventConfig(title: 'Product Transformed', icon: Icons.transform, color: const Color(0xFF0D9488));
      case 'STAGE_CHANGED':
        return _EventConfig(title: 'Stage Advanced', icon: Icons.timeline, color: const Color(0xFF059669));
      case 'STATUS_CHANGED':
        return _EventConfig(title: 'Status Updated', icon: Icons.sync_alt, color: const Color(0xFFF57C00));
      case 'OWNERSHIP_TRANSFERRED':
        return _EventConfig(title: 'Ownership Transferred', icon: Icons.swap_horiz, color: const Color(0xFF5E35B1));
      case 'DISQUALIFIED':
        return _EventConfig(title: 'Batch Disqualified', icon: Icons.highlight_off, color: const Color(0xFFD32F2F));
      case 'ARCHIVED':
        return _EventConfig(title: 'Batch Archived', icon: Icons.archive_outlined, color: const Color(0xFF757575));
      default:
        return _EventConfig(title: type.replaceAll('_', ' '), icon: Icons.history, color: AppColors.primary);
    }
  }
}

class _EventConfig {
  final String title;
  final IconData icon;
  final Color color;

  const _EventConfig({required this.title, required this.icon, required this.color});
}
