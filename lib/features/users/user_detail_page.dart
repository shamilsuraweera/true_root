import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../batches/batch_detail_page.dart';
import '../batches/models/batch.dart';
import '../batches/state/batch_provider.dart';
import '../products/state/product_provider.dart';
import '../profile/state/profile_provider.dart';
import '../requests/state/ownership_requests_provider.dart';
import '../notifications/notifications_provider.dart';
import 'models/user.dart';

class UserDetailPage extends ConsumerWidget {
  final AppUser user;

  const UserDetailPage({super.key, required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final batchesAsync = ref.watch(_userBatchesProvider(user.id));
    final products = ref.watch(productListProvider).valueOrNull;
    final productMap = {
      for (final product in products ?? []) product.id: product.name,
    };

    return Scaffold(
      appBar: AppBar(title: Text(user.displayName)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _InfoRow(label: 'Email', value: user.email),
          _InfoRow(label: 'Role', value: user.roleLabel),
          _InfoRow(label: 'Organization', value: user.organizationLabel),
          _InfoRow(label: 'Location', value: user.locationLabel),
          const SizedBox(height: 24),
          batchesAsync.when(
            data: (batches) {
              if (batches.isEmpty) {
                return const Text('No batches found');
              }
              final items = batches.where((batch) => batch.isItem).toList();
              final regularBatches = batches
                  .where((batch) => !batch.isItem)
                  .toList();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: batches.isEmpty
                    ? const []
                    : [
                        Text(
                          'Items',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        if (items.isEmpty)
                          const Text('No items found')
                        else
                          ...items.map(
                            (batch) => _UserBatchCard(
                              batch: batch,
                              ownerId: user.id,
                              productName: productMap[batch.productId],
                              allowRequest: false,
                              titlePrefix: 'Item',
                            ),
                          ),
                        const SizedBox(height: 24),
                        Text(
                          'Batches',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        if (regularBatches.isEmpty)
                          const Text('No batches found')
                        else
                          ...regularBatches.map(
                            (batch) => _UserBatchCard(
                              batch: batch,
                              ownerId: user.id,
                              productName: productMap[batch.productId],
                            ),
                          ),
                      ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Failed to load batches'),
                TextButton(
                  onPressed: () =>
                      ref.invalidate(_userBatchesProvider(user.id)),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

final _userBatchesProvider = FutureProvider.family<List<Batch>, String>((
  ref,
  userId,
) async {
  final api = ref.watch(batchApiProvider);
  return api.fetchBatches(ownerId: userId, limit: 50, includeInactive: true);
});

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(width: 110, child: Text(label)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _UserBatchCard extends ConsumerWidget {
  final Batch batch;
  final String ownerId;
  final String? productName;
  final bool allowRequest;
  final String titlePrefix;

  const _UserBatchCard({
    required this.batch,
    required this.ownerId,
    this.productName,
    this.allowRequest = true,
    this.titlePrefix = 'Batch',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ownerLabel = batch.ownerName ?? batch.ownerEmail;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(
          '$titlePrefix ${batch.id} • ${productName ?? batch.displayProduct}',
        ),
        subtitle: Text(
          ownerLabel == null
              ? '${batch.quantity} ${batch.unit} • ${batch.status}'
              : '${batch.quantity} ${batch.unit} • ${batch.status} • Owner: $ownerLabel',
        ),
        trailing: allowRequest
            ? ElevatedButton(
                onPressed: () =>
                    _requestOwnership(context, ref, batch, ownerId),
                child: const Text('Request'),
              )
            : null,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BatchDetailPage(batchId: batch.id),
            ),
          );
        },
      ),
    );
  }
}

Future<void> _requestOwnership(
  BuildContext context,
  WidgetRef ref,
  Batch batch,
  String ownerId,
) async {
  final requesterId = ref.read(currentUserIdProvider);
  if (requesterId == ownerId) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('You already own this batch')));
    return;
  }

  var quantityText = batch.quantity.toString();
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Request batch'),
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

  if (confirmed != true) {
    return;
  }

  final quantity = double.tryParse(quantityText.trim());
  if (quantity == null || quantity <= 0) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Enter a valid quantity')));
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
    ref
        .read(notificationsProvider.notifier)
        .add(
          title: 'Request sent',
          message: 'Batch ${batch.id} request sent to owner $ownerId.',
        );
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Request sent')));
  } catch (_) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Failed to send request')));
  }
}
