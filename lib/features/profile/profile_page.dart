import 'package:flutter/material.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController(text: 'Shamil');
  final _orgController = TextEditingController(text: 'True Root Co.');
  final _locationController = TextEditingController(text: 'Kandy');
  String _accountType = 'Individual';
  final List<String> _members = ['nimal@trader.lk', 'exporter@tea.lk'];
  final _memberController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _orgController.dispose();
    _locationController.dispose();
    _memberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const CircleAvatar(radius: 36, child: Icon(Icons.person, size: 36)),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
              validator: (value) => value == null || value.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _orgController,
              decoration: const InputDecoration(labelText: 'Organization'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(labelText: 'Location'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _accountType,
              items: const [
                DropdownMenuItem(value: 'Individual', child: Text('Individual')),
                DropdownMenuItem(value: 'Company', child: Text('Company')),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() => _accountType = value);
              },
              decoration: const InputDecoration(labelText: 'Account Type'),
            ),
            if (_accountType == 'Company') ...[
              const SizedBox(height: 16),
              Text('Members', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _memberController,
                      decoration: const InputDecoration(
                        labelText: 'Add member (email)',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _addMember,
                    child: const Text('Add'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ..._members.map(
                (member) => ListTile(
                  title: Text(member),
                  trailing: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => _removeMember(member),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState?.validate() != true) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profile updated')),
                );
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _addMember() {
    final value = _memberController.text.trim();
    if (value.isEmpty) return;
    setState(() {
      _members.add(value);
      _memberController.clear();
    });
  }

  void _removeMember(String member) {
    setState(() => _members.remove(member));
  }
}
