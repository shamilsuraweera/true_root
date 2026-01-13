import 'package:flutter/material.dart';
import '../batches/batch_detail_page.dart';
import 'models/user.dart';

class UserDetailPage extends StatelessWidget {
  final AppUser user;

  const UserDetailPage({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
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
          _UserBatchCard(
            batchId: '1',
            title: 'Cinnamon Grade A',
            subtitle: '120 kg • ACTIVE',
          ),
          _UserBatchCard(
            batchId: '2',
            title: 'Tea Leaf',
            subtitle: '80 kg • HOLD',
          ),
        ],
      ),
    );
  }
}

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

class _UserBatchCard extends StatelessWidget {
  final String batchId;
  final String title;
  final String subtitle;

  const _UserBatchCard({
    required this.batchId,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: ElevatedButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Request sent')),
            );
          },
          child: const Text('Request'),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => BatchDetailPage(batchId: batchId)),
          );
        },
      ),
    );
  }
}
