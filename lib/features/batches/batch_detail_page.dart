import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'batch_history_timeline.dart';
import 'state/batch_provider.dart';
import '../products/state/product_provider.dart';

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
                  switch (value) {
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
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'split', child: Text('Split batch')),
                  PopupMenuItem(value: 'merge', child: Text('Merge batches')),
                  PopupMenuItem(value: 'transform', child: Text('Transform batch')),
                  PopupMenuDivider(),
                  PopupMenuItem(value: 'archive', child: Text('Archive batch')),
                  PopupMenuItem(value: 'disqualify', child: Text('Mark not suitable')),
                  PopupMenuItem(value: 'delete', child: Text('Delete batch')),
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
                Text('Created: ${batch.createdAt}'),
                const SizedBox(height: 16),
                Text('QR Code', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                _QrPayloadView(batchId: batch.id),
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
      return;
    }

    final newBatchId = transformed['id']?.toString();
    if (newBatchId == null) {
      ref.invalidate(batchByIdProvider(batchId));
      ref.invalidate(batchHistoryProvider(batchId));
      ref.invalidate(batchListProvider);
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
