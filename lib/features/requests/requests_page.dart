import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models/ownership_request.dart';
import 'state/ownership_requests_provider.dart';
import '../batches/state/batch_provider.dart';
import '../products/state/product_provider.dart';
import '../notifications/notifications_provider.dart';

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
    final cachedInbox = ref.watch(cachedOwnershipInboxProvider);

    return inboxAsync.when(
      data: (items) {
        final pending = items.where((item) => item.status == 'PENDING').toList();
        if (pending.isEmpty) {
          return const Center(child: Text('No incoming requests'));
        }
        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(ownershipInboxProvider);
            await ref.read(ownershipInboxProvider.future);
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: pending.length,
            itemBuilder: (context, index) => _InboxCard(request: pending[index]),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) {
        if (cachedInbox.isNotEmpty) {
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(ownershipInboxProvider);
              await ref.read(ownershipInboxProvider.future);
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: cachedInbox.length,
              itemBuilder: (context, index) =>
                  _InboxCard(request: cachedInbox[index]),
            ),
          );
        }
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Failed to load requests'),
              TextButton(
                onPressed: () => ref.invalidate(ownershipInboxProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _OutboxTab extends ConsumerWidget {
  const _OutboxTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final outboxAsync = ref.watch(ownershipOutboxProvider);
    final cachedOutbox = ref.watch(cachedOwnershipOutboxProvider);

    return outboxAsync.when(
      data: (items) {
        final pending = items.where((item) => item.status == 'PENDING').toList();
        if (pending.isEmpty) {
          return const Center(child: Text('No outgoing requests'));
        }
        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(ownershipOutboxProvider);
            await ref.read(ownershipOutboxProvider.future);
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: pending.length,
            itemBuilder: (context, index) => _OutboxCard(request: pending[index]),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) {
        if (cachedOutbox.isNotEmpty) {
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(ownershipOutboxProvider);
              await ref.read(ownershipOutboxProvider.future);
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: cachedOutbox.length,
              itemBuilder: (context, index) =>
                  _OutboxCard(request: cachedOutbox[index]),
            ),
          );
        }
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Failed to load requests'),
              TextButton(
                onPressed: () => ref.invalidate(ownershipOutboxProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _InboxCard extends ConsumerWidget {
  final OwnershipRequest request;

  const _InboxCard({required this.request});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final batchAsync = ref.watch(batchByIdProvider(request.batchId));
    final products = ref.watch(productListProvider).valueOrNull;
    final productMap = {
      for (final product in products ?? []) product.id: product.name,
    };
    final batch = batchAsync.valueOrNull;
    final productName = batch?.productId != null
        ? productMap[batch!.productId]
        : null;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Batch ${request.batchId} • ${productName ?? batch?.displayProduct ?? 'Product'}',
            ),
            const SizedBox(height: 4),
            Text('${request.quantity} ${batch?.unit ?? 'kg'}'),
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
      ref.read(notificationsProvider.notifier).add(
            title: 'Request approved',
            message: 'Purchase request $id approved.',
          );
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
      ref.read(notificationsProvider.notifier).add(
            title: 'Request rejected',
            message: 'Purchase request $id rejected.',
          );
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
        title: _OutboxTitle(request: request),
        subtitle: Text('Owner: ${request.ownerId}'),
        trailing: Text(request.status),
      ),
    );
  }
}

class _OutboxTitle extends ConsumerWidget {
  final OwnershipRequest request;

  const _OutboxTitle({required this.request});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final batchAsync = ref.watch(batchByIdProvider(request.batchId));
    final products = ref.watch(productListProvider).valueOrNull;
    final productMap = {
      for (final product in products ?? []) product.id: product.name,
    };
    final batch = batchAsync.valueOrNull;
    final productName = batch?.productId != null
        ? productMap[batch!.productId]
        : null;
    return Text(
      'Batch ${request.batchId} • ${productName ?? batch?.displayProduct ?? 'Product'}'
      ' • ${request.quantity} ${batch?.unit ?? 'kg'}',
    );
  }
}
