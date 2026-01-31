import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'batch_history_timeline.dart';
import 'state/batch_provider.dart';
import 'models/batch.dart';
import '../products/state/product_provider.dart';
import '../home/state/dashboard_provider.dart';
import 'models/batch_lineage.dart';
import '../stages/state/stage_provider.dart';
import '../stages/models/stage.dart';
import '../requests/state/ownership_requests_provider.dart';
import '../profile/state/profile_provider.dart';

class BatchDetailPage extends ConsumerWidget {
  final String batchId;

  const BatchDetailPage({super.key, required this.batchId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final batchAsync = ref.watch(batchByIdProvider(batchId));

    return batchAsync.when(
      data: (batch) {
        if (batch == null) {
          return const Scaffold(body: Center(child: Text('Batch not found')));
        }

        final lineageAsync = ref.watch(batchLineageProvider(batch.id));
        final hasChildren = lineageAsync.valueOrNull?.children.isNotEmpty ?? false;
        final isLocked = _isLockedBatch(batch) || hasChildren;

        final products = ref.watch(productListProvider).valueOrNull;
        String? productName;
        if (products != null && batch.productId != null) {
          for (final product in products) {
            if (product.id == batch.productId) {
              productName = product.name;
              break;
            }
          }
        }

        return Scaffold(
          appBar: AppBar(
            title: Text('Batch ${batch.id}'),
            actions: [
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (isLocked) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('This batch is locked and cannot be modified')),
                    );
                    return;
                  }
                  switch (value) {
                    case 'update':
                      _showUpdateDialog(context, ref, batch);
                      break;
                    case 'split':
                      _showSplitDialog(context, ref, batch.id, batch.quantity);
                      break;
                    case 'merge':
                      _showMergeDialog(context, ref, batch.id);
                      break;
                    case 'transform':
                      _showTransformDialog(context, ref, batch.id, batch.quantity);
                      break;
                    case 'archive':
                      _archiveBatch(context, ref, batch.id);
                      break;
                    case 'disqualify':
                      _disqualifyBatch(context, ref, batch.id);
                      break;
                    case 'delete':
                      _deleteBatch(context, ref, batch.id);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'update',
                    enabled: !isLocked,
                    child: const Text('Update batch'),
                  ),
                  PopupMenuItem(
                    value: 'split',
                    enabled: !isLocked,
                    child: const Text('Split batch'),
                  ),
                  PopupMenuItem(
                    value: 'merge',
                    enabled: !isLocked,
                    child: const Text('Merge batches'),
                  ),
                  PopupMenuItem(
                    value: 'transform',
                    enabled: !isLocked,
                    child: const Text('Transform batch'),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'archive',
                    enabled: !isLocked,
                    child: const Text('Archive batch'),
                  ),
                  PopupMenuItem(
                    value: 'disqualify',
                    enabled: !isLocked,
                    child: const Text('Mark not suitable'),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    enabled: !isLocked,
                    child: const Text('Delete batch'),
                  ),
                ],
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  productName ?? batch.displayProduct,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text('Quantity: ${batch.quantity} ${batch.unit}'),
                Text('Status: ${batch.status}'),
                if (batch.grade != null && batch.grade!.isNotEmpty) Text('Grade: ${batch.grade}'),
                if (isLocked)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'This batch is locked because it is archived/disqualified or has derived batches.',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Theme.of(context).colorScheme.error),
                    ),
                  ),
                if (batch.ownerId != null &&
                    batch.ownerId != ref.watch(currentUserIdProvider))
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: OutlinedButton.icon(
                      onPressed: () => _requestOwnershipForBatch(context, ref, batch),
                      icon: const Icon(Icons.shopping_cart_outlined),
                      label: const Text('Request purchase'),
                    ),
                  ),
                Text('Created: ${batch.createdAt}'),
                const SizedBox(height: 16),
                Text('QR Code', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                _QrPayloadView(batchId: batch.id),
                const SizedBox(height: 24),
                _BatchLineageSection(batchId: batch.id),
                const SizedBox(height: 24),
                const Text(
                  'History',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Expanded(child: BatchHistoryTimeline(batchId: batch.id)),
              ],
            ),
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stackTrace) => const Scaffold(
        body: Center(child: Text('Failed to load batch')),
      ),
    );
  }
}

class _BatchLineageSection extends ConsumerWidget {
  final String batchId;

  const _BatchLineageSection({required this.batchId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lineageAsync = ref.watch(batchLineageProvider(batchId));
    final products = ref.watch(productListProvider).valueOrNull;
    final Map<int, String> productMap = {
      for (final product in products ?? []) product.id: product.name,
    };
    return lineageAsync.when(
      data: (lineage) {
        if (lineage.parents.isEmpty && lineage.children.isEmpty) {
          return const Text('Lineage: none');
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Lineage', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (lineage.parents.isNotEmpty) ...[
              Text('Parents', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 4),
              ...lineage.parents.map(
                (item) => _LineageItem(
                  item: item,
                  showParent: true,
                  productMap: productMap,
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (lineage.children.isNotEmpty) ...[
              Text('Children', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 4),
              ...lineage.children.map(
                (item) => _LineageItem(
                  item: item,
                  showParent: false,
                  productMap: productMap,
                ),
              ),
            ],
          ],
        );
      },
      loading: () => const Text('Lineage: loading...'),
      error: (_, _) => const Text('Lineage: unavailable'),
    );
  }
}

class _LineageItem extends StatelessWidget {
  final BatchRelationItem item;
  final bool showParent;
  final Map<int, String> productMap;

  const _LineageItem({
    required this.item,
    required this.showParent,
    required this.productMap,
  });

  @override
  Widget build(BuildContext context) {
    final batch = item.batch;
    final relatedId = showParent ? item.parentBatchId : item.childBatchId;
    final quantity = item.quantity;
    final quantityText = quantity == null ? '' : ' • ${quantity.toStringAsFixed(2)}';
    final productName = batch?.productId != null ? productMap[batch!.productId] : null;
    final ownerLabel = batch?.ownerName ?? batch?.ownerEmail;
    final ownerText = ownerLabel == null ? '' : ' • Owner: $ownerLabel';
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => BatchDetailPage(batchId: relatedId)),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Batch $relatedId • ${productName ?? batch?.displayProduct ?? 'Product'}'
                ' • ${item.relationType}$quantityText'
                '${batch == null ? '' : ' • ${batch.status}'}$ownerText',
              ),
            ),
            const Icon(Icons.chevron_right, size: 18),
          ],
        ),
      ),
    );
  }
}

Future<void> _showUpdateDialog(BuildContext context, WidgetRef ref, Batch batch) async {
  var quantityText = batch.quantity.toString();
  var statusText = batch.status;
  var gradeText = batch.grade ?? '';
  int? stageId = batch.stageId;

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return Consumer(
        builder: (context, ref, _) {
          final stagesAsync = ref.watch(stageListProvider);
          final stageItems = _buildStageItems(stagesAsync.valueOrNull);
          return AlertDialog(
            title: const Text('Update batch'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  initialValue: quantityText,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Quantity',
                  ),
                  onChanged: (value) => quantityText = value,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: statusText,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                  ),
                  onChanged: (value) => statusText = value,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int?>(
                  initialValue: stageItems.any((item) => item.value == stageId) ? stageId : null,
                  items: stageItems,
                  onChanged: (value) => stageId = value,
                  decoration: const InputDecoration(labelText: 'Stage'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: gradeText,
                  decoration: const InputDecoration(
                    labelText: 'Grade (optional)',
                  ),
                  onChanged: (value) => gradeText = value,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Update'),
              ),
            ],
          );
        },
      );
    },
  );

  if (confirmed != true) {
    return;
  }

  final quantity = double.tryParse(quantityText.trim());
  if (quantity == null || quantity <= 0) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Enter a valid quantity')),
    );
    return;
  }

  final status = statusText.trim();
  if (status.isEmpty) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Status is required')),
    );
    return;
  }

  final grade = gradeText.trim();
  final updateTasks = <Future<void>>[];
  final api = ref.read(batchApiProvider);

  if (quantity != batch.quantity) {
    updateTasks.add(api.updateQuantity(batch.id, quantity).then((_) {}));
  }

  if (status != batch.status) {
    updateTasks.add(api.updateStatus(batch.id, status).then((_) {}));
  }

  if (grade != (batch.grade ?? '')) {
    if (grade.isEmpty) {
      updateTasks.add(api.updateGrade(batch.id, '').then((_) {}));
    } else {
      updateTasks.add(api.updateGrade(batch.id, grade).then((_) {}));
    }
  }

  if (stageId != batch.stageId) {
    updateTasks.add(api.updateStage(batch.id, stageId).then((_) {}));
  }

  if (updateTasks.isEmpty) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No changes to update')),
    );
    return;
  }

  try {
    await Future.wait(updateTasks);
    ref.invalidate(batchByIdProvider(batch.id));
    ref.invalidate(batchHistoryProvider(batch.id));
    ref.invalidate(batchListProvider);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Batch updated')),
    );
  } catch (error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_errorText(error, 'Failed to update batch'))),
    );
  }
}

Future<void> _showSplitDialog(
  BuildContext context,
  WidgetRef ref,
  String batchId,
  double availableQuantity,
) async {
  var quantitiesText = '';
  var gradesText = '';

  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Split batch'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Quantities (comma separated)',
                hintText: '10,20,30',
              ),
              onChanged: (value) => quantitiesText = value,
            ),
            const SizedBox(height: 12),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Grades (optional, comma separated)',
                hintText: 'A,B',
              ),
              onChanged: (value) => gradesText = value,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Split'),
          ),
        ],
      );
    },
  );

  if (result != true) {
    return;
  }

  final quantities = _parseDoubles(quantitiesText);
  final grades = _parseStrings(gradesText);

  if (quantities.length < 2) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Enter at least two quantities')),
    );
    return;
  }

  if (quantities.any((q) => q <= 0)) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All quantities must be greater than zero')),
    );
    return;
  }

  final total = quantities.fold<double>(0, (sum, q) => sum + q);
  if (total > availableQuantity) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Split total exceeds ${availableQuantity.toStringAsFixed(2)}')),
    );
    return;
  }

  final items = <Map<String, dynamic>>[];
  for (var i = 0; i < quantities.length; i++) {
    final item = <String, dynamic>{'quantity': quantities[i]};
    if (i < grades.length && grades[i].isNotEmpty) {
      item['grade'] = grades[i];
    }
    items.add(item);
  }

  try {
    final api = ref.read(batchApiProvider);
    final response = await api.splitBatch(batchId, items);
    final children = response['children'] as List<dynamic>? ?? [];
    if (!context.mounted) return;
    ref.invalidate(batchByIdProvider(batchId));
    ref.invalidate(batchHistoryProvider(batchId));
    ref.invalidate(batchListProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Split into ${children.length} batches')),
    );
  } catch (error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_errorText(error, 'Failed to split batch'))),
    );
  }
}

Future<void> _showMergeDialog(BuildContext context, WidgetRef ref, String batchId) async {
  var idsText = batchId;
  var productText = '';
  var gradeText = '';

  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Merge batches'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              initialValue: idsText,
              keyboardType: TextInputType.text,
              decoration: const InputDecoration(
                labelText: 'Batch IDs (comma separated)',
                hintText: '1,2,3',
              ),
              onChanged: (value) => idsText = value,
            ),
            const SizedBox(height: 12),
            TextFormField(
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'New product ID',
                hintText: '1',
              ),
              onChanged: (value) => productText = value,
            ),
            const SizedBox(height: 12),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Grade (optional)',
              ),
              onChanged: (value) => gradeText = value,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Merge'),
          ),
        ],
      );
    },
  );

  if (result != true) {
    return;
  }

  final ids = _parseInts(idsText);
  final productId = int.tryParse(productText.trim());
  final grade = gradeText.trim().isEmpty ? null : gradeText.trim();

  final uniqueIds = ids.toSet().toList();
  if (uniqueIds.length < 2 || productId == null) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Enter at least two batch IDs and a product ID')),
    );
    return;
  }

  try {
    final api = ref.read(batchApiProvider);
    final merged = await api.mergeBatches(batchIds: uniqueIds, productId: productId, grade: grade);
    if (!context.mounted) return;
    ref.invalidate(batchByIdProvider(batchId));
    ref.invalidate(batchHistoryProvider(batchId));
    ref.invalidate(batchListProvider);
    ref.invalidate(ownedBatchListProvider);
    ref.invalidate(recentBatchesProvider);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => BatchDetailPage(batchId: merged.id)),
    );
  } catch (error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_errorText(error, 'Failed to merge batches'))),
    );
  }
}

Future<void> _showTransformDialog(
  BuildContext context,
  WidgetRef ref,
  String batchId,
  double availableQuantity,
) async {
  var productText = '';
  var quantityText = '';
  var gradeText = '';

  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Transform batch'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'New product ID',
                hintText: '2',
              ),
              onChanged: (value) => productText = value,
            ),
            const SizedBox(height: 12),
            TextFormField(
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Quantity (optional)',
              ),
              onChanged: (value) => quantityText = value,
            ),
            const SizedBox(height: 12),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Grade (optional)',
              ),
              onChanged: (value) => gradeText = value,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Transform'),
          ),
        ],
      );
    },
  );

  if (result != true) {
    return;
  }

  final productId = int.tryParse(productText.trim());
  final quantity = double.tryParse(quantityText.trim());
  final grade = gradeText.trim().isEmpty ? null : gradeText.trim();

  if (productId == null) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Enter a valid product ID')),
    );
    return;
  }

  if (quantity != null && quantity <= 0) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Quantity must be greater than zero')),
    );
    return;
  }

  if (quantity != null && quantity > availableQuantity) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Quantity exceeds ${availableQuantity.toStringAsFixed(2)}')),
    );
    return;
  }

  try {
    final api = ref.read(batchApiProvider);
    final response = await api.transformBatch(
      batchId: batchId,
      productId: productId,
      quantity: quantity,
      grade: grade,
    );
    final transformed = response['transformed'] as Map<String, dynamic>?;
    if (!context.mounted) return;
    if (transformed == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transform completed')),
      );
      ref.invalidate(batchByIdProvider(batchId));
      ref.invalidate(batchHistoryProvider(batchId));
      ref.invalidate(batchListProvider);
      ref.invalidate(ownedBatchListProvider);
      ref.invalidate(recentBatchesProvider);
      return;
    }

    final newBatchId = transformed['id']?.toString();
    if (newBatchId == null) {
      ref.invalidate(batchByIdProvider(batchId));
      ref.invalidate(batchHistoryProvider(batchId));
      ref.invalidate(batchListProvider);
      ref.invalidate(ownedBatchListProvider);
      ref.invalidate(recentBatchesProvider);
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => BatchDetailPage(batchId: newBatchId)),
    );
  } catch (error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_errorText(error, 'Failed to transform batch'))),
    );
  }
}

String _errorText(Object error, String fallback) {
  final text = error.toString();
  if (text.isEmpty) {
    return fallback;
  }
  return text.replaceFirst('Exception: ', '');
}

bool _isLockedBatch(Batch batch) {
  return batch.isDisqualified ||
      const [
        'MERGED',
        'TRANSFORMED',
        'SPLIT',
        'ARCHIVED',
        'DISQUALIFIED',
        'DELETED',
      ].contains(batch.status);
}

List<DropdownMenuItem<int?>> _buildStageItems(List<Stage>? stages) {
  final items = <DropdownMenuItem<int?>>[
    const DropdownMenuItem(value: null, child: Text('No stage')),
  ];
  if (stages == null) {
    return items;
  }
  final activeStages = stages.where((stage) => stage.active).toList()
    ..sort((a, b) => a.sequence.compareTo(b.sequence));
  items.addAll(
    activeStages.map(
      (stage) => DropdownMenuItem(
        value: stage.id,
        child: Text(stage.name),
      ),
    ),
  );
  return items;
}

void _invalidateRequestLists(WidgetRef ref) {
  ref.invalidate(pendingRequestsProvider);
  ref.invalidate(ownershipInboxProvider);
  ref.invalidate(ownershipOutboxProvider);
}

Future<void> _requestOwnershipForBatch(
  BuildContext context,
  WidgetRef ref,
  Batch batch,
) async {
  final ownerId = batch.ownerId;
  if (ownerId == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Batch has no owner')),
    );
    return;
  }

  final requesterId = ref.read(currentUserIdProvider);
  if (requesterId == null || requesterId.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('You must be logged in')),
    );
    return;
  }
  if (requesterId == ownerId) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('You already own this batch')),
    );
    return;
  }

  var quantityText = batch.quantity.toString();
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Request purchase'),
      content: TextFormField(
        initialValue: quantityText,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(
          labelText: 'Quantity',
          hintText: '10',
        ),
        onChanged: (value) => quantityText = value,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Send'),
        ),
      ],
    ),
  );

  if (confirmed != true) return;

  final quantity = double.tryParse(quantityText.trim());
  if (quantity == null || quantity <= 0) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Enter a valid quantity')),
    );
    return;
  }

  try {
    final api = ref.read(ownershipRequestsApiProvider);
    await api.createRequest(
      batchId: batch.id,
      requesterId: requesterId,
      ownerId: ownerId,
      quantity: quantity,
    );
    _invalidateRequestLists(ref);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Request sent')),
    );
  } catch (error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_errorText(error, 'Failed to send request'))),
    );
  }
}

Future<void> _archiveBatch(BuildContext context, WidgetRef ref, String batchId) async {
  final confirmed = await _confirmAction(
    context,
    title: 'Archive batch?',
    message: 'This will hide the batch from active lists.',
    confirmLabel: 'Archive',
  );
  if (confirmed != true) return;

  try {
    final api = ref.read(batchApiProvider);
    await api.archiveBatch(batchId);
    if (!context.mounted) return;
    ref.invalidate(batchByIdProvider(batchId));
    ref.invalidate(batchListProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Batch archived')),
    );
  } catch (_) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Failed to archive batch')),
    );
  }
}

Future<void> _disqualifyBatch(BuildContext context, WidgetRef ref, String batchId) async {
  final reasonController = TextEditingController();
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Mark not suitable'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            labelText: 'Reason',
            hintText: 'Contaminated / damaged',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Confirm'),
          ),
        ],
      );
    },
  );

  if (confirmed != true) {
    reasonController.dispose();
    return;
  }

  final reason = reasonController.text.trim().isEmpty
      ? 'Marked not suitable for use'
      : reasonController.text.trim();
  reasonController.dispose();

  try {
    final api = ref.read(batchApiProvider);
    await api.disqualifyBatch(batchId, reason);
    if (!context.mounted) return;
    ref.invalidate(batchByIdProvider(batchId));
    ref.invalidate(batchListProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Batch marked not suitable')),
    );
  } catch (_) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Failed to update batch')),
    );
  }
}

Future<void> _deleteBatch(BuildContext context, WidgetRef ref, String batchId) async {
  final confirmed = await _confirmAction(
    context,
    title: 'Delete batch?',
    message: 'This will permanently remove the batch.',
    confirmLabel: 'Delete',
  );
  if (confirmed != true) return;

  try {
    final api = ref.read(batchApiProvider);
    await api.deleteBatch(batchId);
    if (!context.mounted) return;
    ref.invalidate(batchListProvider);
    Navigator.of(context).maybePop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Batch deleted')),
    );
  } catch (_) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Failed to delete batch')),
    );
  }
}

Future<bool?> _confirmAction(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
}) {
  return showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
}

List<double> _parseDoubles(String input) {
  return input
      .split(',')
      .map((value) => double.tryParse(value.trim()))
      .whereType<double>()
      .where((value) => value > 0)
      .toList();
}

List<int> _parseInts(String input) {
  return input
      .split(',')
      .map((value) => int.tryParse(value.trim()))
      .whereType<int>()
      .where((value) => value > 0)
      .toList();
}

List<String> _parseStrings(String input) {
  if (input.trim().isEmpty) return [];
  return input.split(',').map((value) => value.trim()).where((value) => value.isNotEmpty).toList();
}

class _QrPayloadView extends ConsumerWidget {
  final String batchId;

  const _QrPayloadView({required this.batchId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final qrPayload = ref.watch(batchQrPayloadProvider(batchId));

    return qrPayload.when(
      data: (payload) => Center(
        child: QrImageView(
          data: payload,
          size: 180,
          backgroundColor: Colors.white,
        ),
      ),
      loading: () => const SizedBox(
        height: 180,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stackTrace) => SizedBox(
        height: 180,
        child: Center(
          child: Text(
            'Failed to load QR',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ),
    );
  }
}
