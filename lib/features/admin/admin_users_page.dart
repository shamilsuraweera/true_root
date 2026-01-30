import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../users/models/user.dart';
import '../users/state/users_provider.dart';

class AdminUsersPage extends ConsumerStatefulWidget {
  const AdminUsersPage({super.key});

  @override
  ConsumerState<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends ConsumerState<AdminUsersPage> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    ref.invalidate(usersListProvider);
    await ref.read(usersListProvider.future);
  }

  Future<void> _openEditor({AppUser? user}) async {
    final isEditing = user != null;
    final formKey = GlobalKey<FormState>();
    final emailController = TextEditingController(text: user?.email ?? '');
    final nameController = TextEditingController(text: user?.name ?? '');
    final organizationController = TextEditingController(text: user?.organization ?? '');
    final locationController = TextEditingController(text: user?.location ?? '');
    final accountTypeController = TextEditingController(text: user?.accountType ?? '');
    final passwordController = TextEditingController();
    String roleValue = user?.role ?? 'farmer';
    const accountTypeOptions = ['Individual', 'Company'];
    String? accountTypeValue = accountTypeOptions.contains(user?.accountType)
        ? user?.accountType
        : 'Individual';

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(isEditing ? 'Edit User' : 'Create User'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: emailController,
                        decoration: const InputDecoration(labelText: 'Email'),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Email required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: roleValue,
                        decoration: const InputDecoration(labelText: 'Role'),
                        items: const [
                          DropdownMenuItem(value: 'farmer', child: Text('Farmer')),
                          DropdownMenuItem(value: 'trader', child: Text('Trader')),
                          DropdownMenuItem(value: 'exporter', child: Text('Exporter')),
                          DropdownMenuItem(value: 'admin', child: Text('Admin')),
                        ],
                        onChanged: (value) => setState(() {
                          roleValue = value ?? roleValue;
                        }),
                      ),
                      const SizedBox(height: 12),
                      if (!isEditing)
                        TextFormField(
                          controller: passwordController,
                          decoration: const InputDecoration(labelText: 'Password'),
                          obscureText: true,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Password required';
                            }
                            return null;
                          },
                        ),
                      if (!isEditing) const SizedBox(height: 12),
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(labelText: 'Name'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: organizationController,
                        decoration: const InputDecoration(labelText: 'Organization'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: locationController,
                        decoration: const InputDecoration(labelText: 'Location'),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: accountTypeValue,
                        decoration: const InputDecoration(labelText: 'Account Type'),
                        items: const [
                          DropdownMenuItem(value: 'Individual', child: Text('Individual')),
                          DropdownMenuItem(value: 'Company', child: Text('Company')),
                        ],
                        onChanged: (value) => setState(() {
                          accountTypeValue = value ?? accountTypeValue;
                          accountTypeController.text = accountTypeValue ?? '';
                        }),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState?.validate() != true) {
                      return;
                    }
                    Navigator.pop(context, true);
                  },
                  child: Text(isEditing ? 'Save' : 'Create'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != true) {
      return;
    }

    final api = ref.read(usersApiProvider);
    try {
      if (isEditing) {
        await api.updateUser(user.id, {
          'email': emailController.text.trim(),
          'role': roleValue,
          'name': nameController.text.trim().isEmpty ? null : nameController.text.trim(),
          'organization': organizationController.text.trim().isEmpty
              ? null
              : organizationController.text.trim(),
          'location': locationController.text.trim().isEmpty ? null : locationController.text.trim(),
          'accountType': accountTypeController.text.trim().isEmpty
              ? null
              : accountTypeController.text.trim(),
        });
      } else {
        await api.createUser({
          'email': emailController.text.trim(),
          'role': roleValue,
          'password': passwordController.text.trim(),
        });
      }
      await _refresh();
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isEditing ? 'Failed to update user' : 'Failed to create user')),
      );
    }
  }

  Future<void> _deleteUser(AppUser user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete user?'),
          content: Text('Delete ${user.displayName}? This cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
    if (confirm != true) {
      return;
    }

    final api = ref.read(usersApiProvider);
    try {
      await api.deleteUser(user.id);
      await _refresh();
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete user')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(usersListProvider);

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          Row(
            children: [
              Text('Users', style: Theme.of(context).textTheme.titleLarge),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => _openEditor(),
                icon: const Icon(Icons.add),
                label: const Text('Add User'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              labelText: 'Search users',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          usersAsync.when(
            data: (users) {
              final query = _searchController.text.trim().toLowerCase();
              final filtered = query.isEmpty
                  ? users
                  : users.where((user) => user.matches(query)).toList();
              if (filtered.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(child: Text('No users found')),
                );
              }
              return Column(
                children: [
                  for (final user in filtered)
                    Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        title: Text(user.displayName),
                        subtitle: Text('${user.email} • ${user.roleLabel}'),
                        trailing: Wrap(
                          spacing: 8,
                          children: [
                            IconButton(
                              tooltip: 'Edit',
                              icon: const Icon(Icons.edit),
                              onPressed: () => _openEditor(user: user),
                            ),
                            IconButton(
                              tooltip: 'Delete',
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => _deleteUser(user),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, _) => const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: Text('Failed to load users')),
            ),
          ),
        ],
      ),
    );
  }
}
