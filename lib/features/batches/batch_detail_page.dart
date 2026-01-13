import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'batch_history_timeline.dart';
import 'state/batch_provider.dart';

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

        return Scaffold(
          appBar: AppBar(
            title: Text('Batch ${batch.id}'),
            actions: [
              PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'split':
                      _showSplitDialog(context, ref, batch.id);
                      break;
                    case 'merge':
                      _showMergeDialog(context, ref, batch.id);
                      break;
                    case 'transform':
                      _showTransformDialog(context, ref, batch.id);
                      break;
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'split', child: Text('Split batch')),
                  PopupMenuItem(value: 'merge', child: Text('Merge batches')),
                  PopupMenuItem(value: 'transform', child: Text('Transform batch')),
                ],
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(batch.displayProduct, style: Theme.of(context).textTheme.titleLarge),
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
                const Expanded(child: BatchHistoryTimeline()),
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

Future<void> _showSplitDialog(BuildContext context, WidgetRef ref, String batchId) async {
  final quantitiesController = TextEditingController();
  final gradesController = TextEditingController();

  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Split batch'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: quantitiesController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Quantities (comma separated)',
                hintText: '10,20,30',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: gradesController,
              decoration: const InputDecoration(
                labelText: 'Grades (optional, comma separated)',
                hintText: 'A,B',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Split'),
          ),
        ],
      );
    },
  );

  if (result != true) {
    quantitiesController.dispose();
    gradesController.dispose();
    return;
  }

  final quantities = _parseDoubles(quantitiesController.text);
  final grades = _parseStrings(gradesController.text);
  quantitiesController.dispose();
  gradesController.dispose();

  if (quantities.length < 2) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Enter at least two quantities')),
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Split into ${children.length} batches')),
    );
  } catch (_) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Failed to split batch')),
    );
  }
}

Future<void> _showMergeDialog(BuildContext context, WidgetRef ref, String batchId) async {
  final idsController = TextEditingController(text: batchId);
  final productController = TextEditingController();
  final gradeController = TextEditingController();

  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Merge batches'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: idsController,
              keyboardType: TextInputType.text,
              decoration: const InputDecoration(
                labelText: 'Batch IDs (comma separated)',
                hintText: '1,2,3',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: productController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'New product ID',
                hintText: '1',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: gradeController,
              decoration: const InputDecoration(
                labelText: 'Grade (optional)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Merge'),
          ),
        ],
      );
    },
  );

  if (result != true) {
    idsController.dispose();
    productController.dispose();
    gradeController.dispose();
    return;
  }

  final ids = _parseInts(idsController.text);
  final productId = int.tryParse(productController.text.trim());
  final grade = gradeController.text.trim().isEmpty ? null : gradeController.text.trim();
  idsController.dispose();
  productController.dispose();
  gradeController.dispose();

  if (ids.length < 2 || productId == null) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Enter at least two batch IDs and a product ID')),
    );
    return;
  }

  try {
    final api = ref.read(batchApiProvider);
    final merged = await api.mergeBatches(batchIds: ids, productId: productId, grade: grade);
    if (!context.mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => BatchDetailPage(batchId: merged.id)),
    );
  } catch (_) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Failed to merge batches')),
    );
  }
}

Future<void> _showTransformDialog(BuildContext context, WidgetRef ref, String batchId) async {
  final productController = TextEditingController();
  final quantityController = TextEditingController();
  final gradeController = TextEditingController();

  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Transform batch'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: productController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'New product ID',
                hintText: '2',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: quantityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Quantity (optional)',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: gradeController,
              decoration: const InputDecoration(
                labelText: 'Grade (optional)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Transform'),
          ),
        ],
      );
    },
  );

  if (result != true) {
    productController.dispose();
    quantityController.dispose();
    gradeController.dispose();
    return;
  }

  final productId = int.tryParse(productController.text.trim());
  final quantity = double.tryParse(quantityController.text.trim());
  final grade = gradeController.text.trim().isEmpty ? null : gradeController.text.trim();
  productController.dispose();
  quantityController.dispose();
  gradeController.dispose();

  if (productId == null) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Enter a valid product ID')),
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
      return;
    }

    final newBatchId = transformed['id']?.toString();
    if (newBatchId == null) {
      ref.invalidate(batchByIdProvider(batchId));
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => BatchDetailPage(batchId: newBatchId)),
    );
  } catch (_) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Failed to transform batch')),
    );
  }
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
