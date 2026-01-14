import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../batches/batch_detail_page.dart';
import '../batches/models/batch.dart';
import '../batches/state/batch_provider.dart';
import '../profile/state/profile_provider.dart';
import '../requests/state/ownership_requests_provider.dart';
import 'models/user.dart';

class UserDetailPage extends ConsumerWidget {
  final AppUser user;

  const UserDetailPage({super.key, required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final batchesAsync = ref.watch(_userBatchesProvider(user.id));

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
          Text('Batches', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          batchesAsync.when(
            data: (batches) {
              if (batches.isEmpty) {
                return const Text('No batches found');
              }
              return Column(
                children: batches
                    .map(
                      (batch) => _UserBatchCard(
                        batch: batch,
                        ownerId: user.id,
                      ),
                    )
                    .toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => const Text('Failed to load batches'),
          ),
        ],
      ),
    );
  }
}

final _userBatchesProvider = FutureProvider.family<List<Batch>, String>((ref, userId) async {
  final api = ref.read(batchApiProvider);
  return api.fetchBatches(ownerId: userId, limit: 50);
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

  const _UserBatchCard({
    required this.batch,
    required this.ownerId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(batch.displayProduct),
        subtitle: Text('${batch.quantity} ${batch.unit} • ${batch.status}'),
        trailing: ElevatedButton(
          onPressed: () => _requestOwnership(context, ref, batch, ownerId),
          child: const Text('Request'),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => BatchDetailPage(batchId: batch.id)),
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
  final qtyController = TextEditingController(text: batch.quantity.toString());
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Request batch'),
      content: TextField(
        controller: qtyController,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(
          labelText: 'Quantity',
          hintText: '10',
        ),
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
    qtyController.dispose();
    return;
  }

  final quantity = double.tryParse(qtyController.text.trim());
  qtyController.dispose();
  if (quantity == null || quantity <= 0) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Enter a valid quantity')),
    );
    return;
  }

  try {
    final requesterId = ref.read(currentUserIdProvider);
    final api = ref.read(ownershipRequestsApiProvider);
    await api.createRequest(
      batchId: batch.id,
      requesterId: requesterId,
      ownerId: ownerId,
      quantity: quantity,
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Request sent')),
    );
  } catch (_) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Failed to send request')),
    );
  }
}
