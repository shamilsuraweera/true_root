import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/theme/app_colors.dart';
import 'batch_history_timeline.dart';
import 'state/batch_provider.dart';
import 'models/batch.dart';
import '../products/state/product_provider.dart';
import '../home/state/dashboard_provider.dart';
import 'models/batch_lineage.dart';
import '../stages/state/stage_provider.dart';
import '../stages/models/stage.dart';
import '../requests/state/ownership_requests_provider.dart';
import '../notifications/notifications_provider.dart';
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
          return Scaffold(
            appBar: AppBar(title: const Text('Batch Details')),
            body: const Center(child: Text('Batch not found')),
          );
        }

        final lineageAsync = ref.watch(batchLineageProvider(batch.id));
        final hasChildren = lineageAsync.valueOrNull?.children.isNotEmpty ?? false;
        final isLocked = _isLockedBatch(batch) || hasChildren;

        final products = ref.watch(productListProvider).valueOrNull;
        final stages = ref.watch(stageListProvider).valueOrNull;
        String? productName;
        String? stageName;
        if (products != null && batch.productId != null) {
          for (final product in products) {
            if (product.id == batch.productId) {
              productName = product.name;
              break;
            }
          }
        }
        if (stages != null && batch.stageId != null) {
          for (final stage in stages) {
            if (stage.id == batch.stageId) {
              stageName = stage.name;
              break;
            }
          }
        }

        final statusColor = AppColors.statusColor(batch.status);
        final currentUserId = ref.watch(currentUserIdProvider);
        final isOwner = batch.ownerId != null && batch.ownerId.toString() == currentUserId;

        return Scaffold(
          appBar: AppBar(
            title: Text('${batch.isItem ? 'Item' : 'Batch'} #${batch.id}'),
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.copy_outlined),
                tooltip: 'Copy Batch ID',
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: batch.id));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Copied Batch ID #${batch.id}')),
                  );
                },
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) {
                  if (isLocked && ['update', 'split', 'merge', 'transform', 'delete'].contains(value)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('This batch is locked and cannot be modified'),
                      ),
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
                    child: const Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 18),
                        SizedBox(width: 8),
                        Text('Update details'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'split',
                    enabled: !isLocked,
                    child: const Row(
                      children: [
                        Icon(Icons.call_split, size: 18),
                        SizedBox(width: 8),
                        Text('Split batch'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'merge',
                    enabled: !isLocked,
                    child: const Row(
                      children: [
                        Icon(Icons.merge_type, size: 18),
                        SizedBox(width: 8),
                        Text('Merge batches'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'transform',
                    enabled: !isLocked,
                    child: const Row(
                      children: [
                        Icon(Icons.transform, size: 18),
                        SizedBox(width: 8),
                        Text('Transform product'),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'archive',
                    enabled: !isLocked,
                    child: const Row(
                      children: [
                        Icon(Icons.archive_outlined, size: 18),
                        SizedBox(width: 8),
                        Text('Archive batch'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'disqualify',
                    enabled: !isLocked,
                    child: const Row(
                      children: [
                        Icon(Icons.cancel_outlined, size: 18, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Mark not suitable', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    enabled: !isLocked,
                    child: const Row(
                      children: [
                        Icon(Icons.delete_outline, size: 18, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete permanently', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Hero Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary,
                        AppColors.primary.withValues(alpha: 0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              batch.isItem ? 'SINGLE ITEM' : 'BULK LOT',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              batch.status.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        productName ?? batch.displayProduct,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Created: ${batch.createdAt.toLocal().toString().split(' ').first}',
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ),

                if (isLocked) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber.shade300),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.lock_outline, color: Colors.amber.shade900, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'This batch is locked because it is finalized, archived, or has child derived batches.',
                            style: TextStyle(color: Colors.amber.shade900, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 16),
                // Metric Tiles 2x2 Grid
                Row(
                  children: [
                    Expanded(
                      child: _MetricTile(
                        icon: Icons.scale_outlined,
                        iconColor: AppColors.primary,
                        label: 'Quantity',
                        value: '${batch.quantity.toStringAsFixed(batch.quantity.truncateToDouble() == batch.quantity ? 0 : 2)} ${batch.unit}',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MetricTile(
                        icon: Icons.timeline_outlined,
                        iconColor: Colors.purple,
                        label: 'Current Stage',
                        value: stageName ?? (batch.stageId != null ? 'Stage #${batch.stageId}' : 'None'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _MetricTile(
                        icon: Icons.star_outline,
                        iconColor: Colors.amber,
                        label: 'Grade / Quality',
                        value: (batch.grade != null && batch.grade!.isNotEmpty) ? batch.grade! : 'Standard',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MetricTile(
                        icon: Icons.person_outline,
                        iconColor: Colors.teal,
                        label: 'Owner',
                        value: batch.ownerName ?? batch.ownerEmail ?? 'System',
                      ),
                    ),
                  ],
                ),

                // Ownership request button if not owned
                if (!batch.isItem && !isOwner && batch.ownerId != null) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _requestOwnershipForBatch(context, ref, batch),
                      icon: const Icon(Icons.shopping_cart_outlined),
                      label: const Text('Request Purchase / Transfer'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],

                // Action buttons row if not locked
                if (!isLocked) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showSplitDialog(context, ref, batch.id, batch.quantity),
                          icon: const Icon(Icons.call_split, size: 18),
                          label: const Text('Split'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showMergeDialog(context, ref, batch.id),
                          icon: const Icon(Icons.merge_type, size: 18),
                          label: const Text('Merge'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showTransformDialog(context, ref, batch.id, batch.quantity),
                          icon: const Icon(Icons.transform, size: 18),
                          label: const Text('Transform'),
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 24),
                // QR Code Section
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.qr_code_2, color: Theme.of(context).colorScheme.primary),
                                const SizedBox(width: 8),
                                Text(
                                  'QR Traceability Code',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ],
                            ),
                            TextButton.icon(
                              onPressed: () async {
                                final api = ref.read(batchApiProvider);
                                try {
                                  final payload = await api.fetchQrPayload(batch.id);
                                  Clipboard.setData(ClipboardData(text: payload));
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('QR payload copied to clipboard')),
                                    );
                                  }
                                } catch (_) {}
                              },
                              icon: const Icon(Icons.copy, size: 16),
                              label: const Text('Copy Data'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Center(child: _QrPayloadView(batchId: batch.id)),
                        const SizedBox(height: 8),
                        Center(
                          child: Text(
                            'Scan with True Root mobile app to verify origin & authenticity',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                // Batch Lineage Section
                _BatchLineageSection(batchId: batch.id),

                const SizedBox(height: 24),
                // History Section
                Row(
                  children: [
                    Icon(Icons.history, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Batch History & Audit Trail',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                BatchHistoryTimeline(batchId: batch.id),
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stackTrace) => Scaffold(
        appBar: AppBar(title: const Text('Batch Details')),
        body: Center(child: Text('Failed to load batch: $error')),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _MetricTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: iconColor),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
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
          return const SizedBox.shrink();
        }
        return Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.account_tree_outlined, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Batch Lineage & Relations',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                if (lineage.parents.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text('Source / Parent Batches:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 6),
                  ...lineage.parents.map(
                    (item) => _LineageItem(
                      item: item,
                      showParent: true,
                      productMap: productMap,
                    ),
                  ),
                ],
                if (lineage.children.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text('Derived / Child Batches:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 6),
                  ...lineage.children.map(
                    (item) => _LineageItem(
                      item: item,
                      showParent: false,
                      productMap: productMap,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
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
    final ownerText = ownerLabel == null ? '' : ' • $ownerLabel';

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.2)),
      ),
      child: ListTile(
        dense: true,
        leading: Icon(
          showParent ? Icons.arrow_upward : Icons.arrow_downward,
          size: 18,
          color: showParent ? Colors.teal : Colors.deepOrange,
        ),
        title: Text(
          'Batch #$relatedId: ${productName ?? batch?.displayProduct ?? 'Product'}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        subtitle: Text(
          '${item.relationType}$quantityText$ownerText',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => BatchDetailPage(batchId: relatedId)),
          );
        },
      ),
    );
  }
}

Future<void> _showUpdateDialog(
  BuildContext context,
  WidgetRef ref,
  Batch batch,
) async {
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Update Batch'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    initialValue: quantityText,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Quantity', border: OutlineInputBorder()),
                    onChanged: (value) => quantityText = value,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: ['ACTIVE', 'TRANSFERRED', 'SPLIT', 'MERGED', 'TRANSFORMED', 'ARCHIVED', 'DISQUALIFIED'].contains(statusText)
                        ? statusText
                        : null,
                    decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'ACTIVE', child: Text('ACTIVE')),
                      DropdownMenuItem(value: 'TRANSFERRED', child: Text('TRANSFERRED')),
                      DropdownMenuItem(value: 'SPLIT', child: Text('SPLIT')),
                      DropdownMenuItem(value: 'MERGED', child: Text('MERGED')),
                      DropdownMenuItem(value: 'TRANSFORMED', child: Text('TRANSFORMED')),
                      DropdownMenuItem(value: 'ARCHIVED', child: Text('ARCHIVED')),
                      DropdownMenuItem(value: 'DISQUALIFIED', child: Text('DISQUALIFIED')),
                    ],
                    onChanged: (value) {
                      if (value != null) statusText = value;
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int?>(
                    initialValue: stageItems.any((item) => item.value == stageId) ? stageId : null,
                    items: stageItems,
                    onChanged: (value) => stageId = value,
                    decoration: const InputDecoration(labelText: 'Stage', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: gradeText,
                    decoration: const InputDecoration(labelText: 'Grade / Quality (optional)', border: OutlineInputBorder()),
                    onChanged: (value) => gradeText = value,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Save Changes'),
              ),
            ],
          );
        },
      );
    },
  );

  if (confirmed != true) return;

  final quantity = double.tryParse(quantityText.trim());
  if (quantity == null || quantity <= 0) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid positive quantity')));
    return;
  }

  final status = statusText.trim();
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
    updateTasks.add(api.updateGrade(batch.id, grade).then((_) {}));
  }
  if (stageId != batch.stageId) {
    updateTasks.add(api.updateStage(batch.id, stageId).then((_) {}));
  }

  if (updateTasks.isEmpty) return;

  try {
    await Future.wait(updateTasks);
    ref.invalidate(batchByIdProvider(batch.id));
    ref.invalidate(batchHistoryProvider(batch.id));
    ref.invalidate(batchListProvider);
    ref.invalidate(ownedBatchListProvider);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Batch updated successfully')),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Split Batch'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Available: ${availableQuantity.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
            ),
            const SizedBox(height: 12),
            TextFormField(
              keyboardType: TextInputType.text,
              decoration: const InputDecoration(
                labelText: 'Portions (comma-separated)',
                hintText: 'e.g. 20, 30',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => quantitiesText = value,
            ),
            const SizedBox(height: 12),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Grades (comma-separated, optional)',
                hintText: 'e.g. Grade A, Grade B',
                border: OutlineInputBorder(),
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
            child: const Text('Split Now'),
          ),
        ],
      );
    },
  );

  if (result != true) return;

  final quantities = _parseDoubles(quantitiesText);
  final grades = _parseStrings(gradesText);

  if (quantities.length < 2) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Enter at least two portions (comma-separated)')),
    );
    return;
  }

  final total = quantities.fold<double>(0, (sum, q) => sum + q);
  if (total > availableQuantity) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Total ($total) exceeds available ($availableQuantity)')),
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
    ref.invalidate(ownedBatchListProvider);
    ref.invalidate(recentBatchesProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Successfully split into ${children.length} batches')),
    );
  } catch (error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_errorText(error, 'Failed to split batch'))),
    );
  }
}

Future<void> _showMergeDialog(
  BuildContext context,
  WidgetRef ref,
  String batchId,
) async {
  var idsText = batchId;
  int? selectedProductId;
  var mergedItemNameText = '';
  var gradeText = '';

  final products = ref.read(productListProvider).valueOrNull ?? [];

  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Merge Batches'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  initialValue: idsText,
                  keyboardType: TextInputType.text,
                  decoration: const InputDecoration(
                    labelText: 'Batch IDs to merge (comma-separated)',
                    hintText: 'e.g. 1, 2, 3',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) => idsText = value,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int?>(
                  initialValue: selectedProductId,
                  decoration: const InputDecoration(
                    labelText: 'Target Product',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('Custom Merged Product Name'),
                    ),
                    ...products.map((p) => DropdownMenuItem<int?>(
                          value: p.id,
                          child: Text(p.name),
                        )),
                  ],
                  onChanged: (val) {
                    setDialogState(() => selectedProductId = val);
                  },
                ),
                if (selectedProductId == null) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Merged Product Name',
                      hintText: 'e.g. Spice Blend Powder',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) => mergedItemNameText = value,
                  ),
                ],
                const SizedBox(height: 12),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Grade (optional)',
                    hintText: 'e.g. Premium',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) => gradeText = value,
                ),
              ],
            ),
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
        ),
      );
    },
  );

  if (result != true) return;

  final ids = _parseInts(idsText);
  final newProductName = mergedItemNameText.trim().isEmpty ? null : mergedItemNameText.trim();
  final grade = gradeText.trim().isEmpty ? null : gradeText.trim();

  final uniqueIds = ids.toSet().toList();
  if (uniqueIds.length < 2 || (selectedProductId == null && newProductName == null)) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Enter at least two batch IDs and select a target product or name'),
      ),
    );
    return;
  }

  try {
    final api = ref.read(batchApiProvider);
    final merged = await api.mergeBatches(
      batchIds: uniqueIds,
      productId: selectedProductId,
      newProductName: newProductName,
      grade: grade,
    );
    if (!context.mounted) return;
    ref.invalidate(batchByIdProvider(batchId));
    ref.invalidate(batchHistoryProvider(batchId));
    ref.invalidate(batchListProvider);
    ref.invalidate(ownedBatchListProvider);
    ref.invalidate(recentBatchesProvider);
    final mergedBatchId = merged['id']?.toString();
    if (mergedBatchId != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => BatchDetailPage(batchId: mergedBatchId)),
      );
    }
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
  int? selectedProductId;
  var quantityText = availableQuantity.toString();
  var gradeText = '';

  final products = ref.read(productListProvider).valueOrNull ?? [];

  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Transform Batch Product'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<int>(
                  initialValue: selectedProductId,
                  decoration: const InputDecoration(
                    labelText: 'New Processed Product',
                    border: OutlineInputBorder(),
                  ),
                  items: products.map((p) => DropdownMenuItem<int>(
                        value: p.id,
                        child: Text(p.name),
                      )).toList(),
                  onChanged: (val) => setDialogState(() => selectedProductId = val),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: quantityText,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Transformed Output Quantity',
                    hintText: availableQuantity.toString(),
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (value) => quantityText = value,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'New Grade / Standard (optional)',
                    hintText: 'e.g. Export Grade',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) => gradeText = value,
                ),
              ],
            ),
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
        ),
      );
    },
  );

  if (result != true || selectedProductId == null) return;

  final quantity = double.tryParse(quantityText.trim());
  final grade = gradeText.trim().isEmpty ? null : gradeText.trim();

  try {
    final api = ref.read(batchApiProvider);
    final response = await api.transformBatch(
      batchId: batchId,
      productId: selectedProductId!,
      quantity: quantity,
      grade: grade,
    );
    final transformed = response['transformed'] as Map<String, dynamic>?;
    if (!context.mounted) return;
    ref.invalidate(batchByIdProvider(batchId));
    ref.invalidate(batchHistoryProvider(batchId));
    ref.invalidate(batchListProvider);
    ref.invalidate(ownedBatchListProvider);
    ref.invalidate(recentBatchesProvider);
    final newBatchId = transformed?['id']?.toString();
    if (newBatchId != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => BatchDetailPage(batchId: newBatchId)),
      );
    }
  } catch (error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_errorText(error, 'Failed to transform batch'))),
    );
  }
}

String _errorText(Object error, String fallback) {
  final text = error.toString();
  if (text.isEmpty) return fallback;
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
      ].contains(batch.status.toUpperCase());
}

List<DropdownMenuItem<int?>> _buildStageItems(List<Stage>? stages) {
  final items = <DropdownMenuItem<int?>>[
    const DropdownMenuItem(value: null, child: Text('No stage')),
  ];
  if (stages == null) return items;
  final activeStages = stages.where((stage) => stage.active).toList()
    ..sort((a, b) => a.sequence.compareTo(b.sequence));
  items.addAll(
    activeStages.map(
      (stage) => DropdownMenuItem(value: stage.id, child: Text(stage.name)),
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
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Batch has no registered owner')));
    return;
  }

  final requesterId = ref.read(currentUserIdProvider);
  if (requesterId.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('You must be logged in')));
    return;
  }
  if (requesterId == ownerId.toString()) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('You already own this batch')));
    return;
  }

  var quantityText = batch.quantity.toString();
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Request Purchase / Transfer'),
      content: TextFormField(
        initialValue: quantityText,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: 'Requested Quantity (${batch.unit})',
          hintText: batch.quantity.toString(),
          border: const OutlineInputBorder(),
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
          child: const Text('Send Request'),
        ),
      ],
    ),
  );

  if (confirmed != true) return;

  final quantity = double.tryParse(quantityText.trim());
  if (quantity == null || quantity <= 0) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid quantity')));
    return;
  }

  try {
    final api = ref.read(ownershipRequestsApiProvider);
    await api.createRequest(
      batchId: batch.id,
      requesterId: requesterId,
      ownerId: ownerId.toString(),
      quantity: quantity,
    );
    _invalidateRequestLists(ref);
    ref.read(notificationsProvider.notifier).add(
          title: 'Transfer Request Sent',
          message: 'Requested $quantity ${batch.unit} of Batch #${batch.id}.',
        );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ownership request sent to owner')),
    );
  } catch (error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_errorText(error, 'Failed to send request'))),
    );
  }
}

Future<void> _archiveBatch(
  BuildContext context,
  WidgetRef ref,
  String batchId,
) async {
  final confirmed = await _confirmAction(
    context,
    title: 'Archive Batch?',
    message: 'This will mark the batch as archived and lock modifications.',
    confirmLabel: 'Archive',
  );
  if (confirmed != true) return;

  try {
    final api = ref.read(batchApiProvider);
    await api.archiveBatch(batchId);
    if (!context.mounted) return;
    ref.invalidate(batchByIdProvider(batchId));
    ref.invalidate(batchListProvider);
    ref.invalidate(ownedBatchListProvider);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Batch archived')));
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to archive: $e')));
  }
}

Future<void> _disqualifyBatch(
  BuildContext context,
  WidgetRef ref,
  String batchId,
) async {
  final reasonController = TextEditingController();
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Mark Not Suitable / Disqualified'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            labelText: 'Reason for Disqualification',
            hintText: 'e.g. Moisture excess, pesticide residue',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Disqualify'),
          ),
        ],
      );
    },
  );

  if (confirmed != true) return;

  final reason = reasonController.text.trim().isEmpty ? 'Marked not suitable for use' : reasonController.text.trim();

  try {
    final api = ref.read(batchApiProvider);
    await api.disqualifyBatch(batchId, reason);
    if (!context.mounted) return;
    ref.invalidate(batchByIdProvider(batchId));
    ref.invalidate(batchListProvider);
    ref.invalidate(ownedBatchListProvider);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Batch marked disqualified')));
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update: $e')));
  }
}

Future<void> _deleteBatch(
  BuildContext context,
  WidgetRef ref,
  String batchId,
) async {
  final confirmed = await _confirmAction(
    context,
    title: 'Delete Batch?',
    message: 'This will permanently delete the batch. This action cannot be undone.',
    confirmLabel: 'Delete',
  );
  if (confirmed != true) return;

  try {
    final api = ref.read(batchApiProvider);
    await api.deleteBatch(batchId);
    if (!context.mounted) return;
    ref.invalidate(batchListProvider);
    ref.invalidate(ownedBatchListProvider);
    Navigator.of(context).maybePop();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Batch deleted')));
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
  return input
      .split(',')
      .map((value) => value.trim())
      .where((value) => value.isNotEmpty)
      .toList();
}

class _QrPayloadView extends ConsumerWidget {
  final String batchId;

  const _QrPayloadView({required this.batchId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final qrPayload = ref.watch(batchQrPayloadProvider(batchId));

    return qrPayload.when(
      data: (payload) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: QrImageView(
          data: payload,
          size: 190,
          backgroundColor: Colors.white,
        ),
      ),
      loading: () => const SizedBox(
        height: 190,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stackTrace) => SizedBox(
        height: 190,
        child: Center(
          child: Text(
            'Failed to load QR code',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ),
    );
  }
}
