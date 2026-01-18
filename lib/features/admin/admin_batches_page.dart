import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../batches/batch_history_timeline.dart';
import '../batches/models/batch.dart';
import '../batches/state/batch_provider.dart';

class AdminBatchesPage extends ConsumerStatefulWidget {
  const AdminBatchesPage({super.key});

  @override
  ConsumerState<AdminBatchesPage> createState() => _AdminBatchesPageState();
}

class _AdminBatchesPageState extends ConsumerState<AdminBatchesPage> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    ref.invalidate(batchListProvider);
    await ref.read(batchListProvider.future);
  }

  void _showHistory(Batch batch) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        final height = MediaQuery.of(context).size.height * 0.7;
        return SafeArea(
          child: SizedBox(
            height: height,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Text('History · Batch ${batch.id}',
                          style: Theme.of(context).textTheme.titleMedium),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: BatchHistoryTimeline(batchId: batch.id),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDetails(Batch batch) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Batch ${batch.id}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DetailRow(label: 'Product', value: batch.displayProduct),
              _DetailRow(label: 'Owner', value: batch.ownerId ?? 'Unknown'),
              _DetailRow(
                label: 'Quantity',
                value: '${batch.quantity.toStringAsFixed(1)} ${batch.unit}',
              ),
              _DetailRow(label: 'Status', value: batch.status),
              _DetailRow(label: 'Grade', value: batch.grade ?? '—'),
              _DetailRow(
                label: 'Created',
                value: batch.createdAt.toLocal().toIso8601String(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _showHistory(batch);
              },
              child: const Text('View History'),
            ),
          ],
        );
      },
    );
  }

  bool _matches(Batch batch, String query) {
    if (query.isEmpty) return true;
    final lower = query.toLowerCase();
    return batch.id.toLowerCase().contains(lower) ||
        batch.displayProduct.toLowerCase().contains(lower) ||
        (batch.ownerId ?? '').toLowerCase().contains(lower) ||
        batch.status.toLowerCase().contains(lower) ||
        (batch.grade ?? '').toLowerCase().contains(lower);
  }

  @override
  Widget build(BuildContext context) {
    final batchesAsync = ref.watch(batchListProvider);

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          Row(
            children: [
              Text('Batches', style: Theme.of(context).textTheme.titleLarge),
              const Spacer(),
              IconButton(
                tooltip: 'Refresh',
                onPressed: _refresh,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              labelText: 'Search batches',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          batchesAsync.when(
            data: (batches) {
              final query = _searchController.text.trim().toLowerCase();
              final filtered = batches.where((batch) => _matches(batch, query)).toList();
              if (filtered.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(child: Text('No batches found')),
                );
              }
              return Column(
                children: [
                  for (final batch in filtered)
                    Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        title: Text(batch.displayProduct),
                        subtitle: Text('Batch ${batch.id} • ${batch.quantity} ${batch.unit}'),
                        trailing: Wrap(
                          spacing: 8,
                          children: [
                            Text(
                              batch.status,
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                            IconButton(
                              tooltip: 'Details',
                              icon: const Icon(Icons.info_outline),
                              onPressed: () => _showDetails(batch),
                            ),
                            IconButton(
                              tooltip: 'History',
                              icon: const Icon(Icons.history),
                              onPressed: () => _showHistory(batch),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, _) => const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: Text('Failed to load batches')),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
