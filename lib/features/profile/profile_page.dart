import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app_routes.dart';
import '../../state/auth_state.dart';
import '../auth/state/auth_provider.dart';
import '../users/models/user.dart';
import '../users/state/users_provider.dart';
import 'state/profile_provider.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _orgController = TextEditingController();
  final _locationController = TextEditingController();
  String _accountType = 'Individual';
  final List<String> _members = [];
  final _memberController = TextEditingController();
  bool _initialized = false;

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
    final profileAsync = ref.watch(profileProvider);
    final usersAsync = ref.watch(usersListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: profileAsync.when(
          data: (profile) {
            if (!_initialized) {
              _nameController.text = profile.name ?? '';
              _orgController.text = profile.organization ?? '';
              _locationController.text = profile.location ?? '';
              _accountType = profile.accountType ?? 'Individual';
              _members
                ..clear()
                ..addAll(profile.members);
              _initialized = true;
            }

            return Form(
              key: _formKey,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
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
                    initialValue: _accountType,
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
                          onPressed: () => _addMember(usersAsync),
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
                    onPressed: () => _save(profile.id),
                    child: const Text('Save'),
                  ),
                ],
              ),
            );
          },
          loading: () => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: const [
              SizedBox(height: 200),
              Center(child: CircularProgressIndicator()),
            ],
          ),
          error: (_, _) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: const [
              SizedBox(height: 200),
              Center(child: Text('Failed to load profile')),
            ],
          ),
        ),
      ),
    );
  }

  void _addMember(AsyncValue<List<AppUser>> usersAsync) {
    final value = _memberController.text.trim();
    if (value.isEmpty) return;
    final users = usersAsync.valueOrNull ?? [];
    final exists = users.any((user) => user.email.toLowerCase() == value.toLowerCase());
    if (!exists) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not found')),
      );
      return;
    }
    if (_members.contains(value)) {
      _memberController.clear();
      return;
    }
    setState(() {
      _members.add(value);
      _memberController.clear();
    });
  }

  void _removeMember(String member) {
    setState(() => _members.remove(member));
  }

  Future<void> _save(String userId) async {
    if (_formKey.currentState?.validate() != true) return;
    final api = ref.read(usersApiProvider);
    try {
      await api.updateUser(userId, {
        'name': _nameController.text.trim(),
        'organization': _orgController.text.trim(),
        'location': _locationController.text.trim(),
        'accountType': _accountType,
        'members': _accountType == 'Company' ? _members : [],
      });
      ref.invalidate(profileProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save profile')),
      );
    }
  }

  Future<void> _refresh() async {
    setState(() => _initialized = false);
    ref.invalidate(profileProvider);
    ref.invalidate(usersListProvider);
    await ref.read(profileProvider.future);
  }

  void _logout() {
    ref.read(authProvider.notifier).logout();
    ref.read(authStorageProvider).clearActiveEmail();
    Navigator.of(context, rootNavigator: true)
        .pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
  }
}
