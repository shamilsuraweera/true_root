import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models/ownership_request.dart';
import 'state/ownership_requests_provider.dart';
import '../batches/state/batch_provider.dart';

class RequestsPage extends ConsumerStatefulWidget {
  const RequestsPage({super.key});

  @override
  ConsumerState<RequestsPage> createState() => _RequestsPageState();
}

class _RequestsPageState extends ConsumerState<RequestsPage> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Requests'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Incoming'),
            Tab(text: 'Outgoing'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _InboxTab(),
          _OutboxTab(),
        ],
      ),
    );
  }
}

class _InboxTab extends ConsumerWidget {
  const _InboxTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inboxAsync = ref.watch(ownershipInboxProvider);

    return inboxAsync.when(
      data: (items) {
        if (items.isEmpty) {
          return const Center(child: Text('No incoming requests'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          itemBuilder: (context, index) => _InboxCard(request: items[index]),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => const Center(child: Text('Failed to load requests')),
    );
  }
}

class _OutboxTab extends ConsumerWidget {
  const _OutboxTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final outboxAsync = ref.watch(ownershipOutboxProvider);

    return outboxAsync.when(
      data: (items) {
        if (items.isEmpty) {
          return const Center(child: Text('No outgoing requests'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          itemBuilder: (context, index) => _OutboxCard(request: items[index]),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => const Center(child: Text('Failed to load requests')),
    );
  }
}

class _InboxCard extends ConsumerWidget {
  final OwnershipRequest request;

  const _InboxCard({required this.request});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Batch ${request.batchId} • ${request.quantity} kg'),
            const SizedBox(height: 4),
            Text('Requester: ${request.requesterId}'),
            const SizedBox(height: 12),
            if (request.status == 'PENDING')
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _reject(context, ref, request.id),
                      child: const Text('Reject'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _approve(context, ref, request.id),
                      child: const Text('Approve'),
                    ),
                  ),
                ],
              )
            else
              Text('Status: ${request.status}'),
          ],
        ),
      ),
    );
  }

  Future<void> _approve(BuildContext context, WidgetRef ref, String id) async {
    try {
      final api = ref.read(ownershipRequestsApiProvider);
      await api.approve(id);
      ref.invalidate(ownershipInboxProvider);
      ref.invalidate(ownershipOutboxProvider);
      ref.invalidate(ownedBatchListProvider);
      ref.invalidate(batchListProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request approved')),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to approve request')),
      );
    }
  }

  Future<void> _reject(BuildContext context, WidgetRef ref, String id) async {
    try {
      final api = ref.read(ownershipRequestsApiProvider);
      await api.reject(id);
      ref.invalidate(ownershipInboxProvider);
      ref.invalidate(ownershipOutboxProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request rejected')),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to reject request')),
      );
    }
  }
}

class _OutboxCard extends StatelessWidget {
  final OwnershipRequest request;

  const _OutboxCard({required this.request});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text('Batch ${request.batchId} • ${request.quantity} kg'),
        subtitle: Text('Owner: ${request.ownerId}'),
        trailing: Text(request.status),
      ),
    );
  }
}
