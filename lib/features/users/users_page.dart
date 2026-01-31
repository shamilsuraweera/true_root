import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'state/users_provider.dart';
import 'user_detail_page.dart';

class UsersPage extends ConsumerStatefulWidget {
  const UsersPage({super.key});

  @override
  ConsumerState<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends ConsumerState<UsersPage> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(usersListProvider);

    return Scaffold(
      appBar: AppBar(
        title: _AppSearchField(
          controller: _searchController,
          hintText: 'Search users',
          onChanged: (_) => setState(() {}),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('No notifications')),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(usersListProvider);
          await ref.read(usersListProvider.future);
        },
        child: Column(
          children: [
            Expanded(
              child: usersAsync.when(
                data: (users) {
                  final query = _searchController.text.trim().toLowerCase();
                  final filtered = query.isEmpty
                      ? users
                      : users.where((user) => user.matches(query)).toList();
                  if (filtered.isEmpty) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 200),
                        Center(child: Text('No users found')),
                      ],
                    );
                  }
                  return ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final user = filtered[index];
                      return ListTile(
                        title: Text(user.displayName),
                        subtitle: Text('${user.organizationLabel} • ${user.roleLabel} • ${user.locationLabel}'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => UserDetailPage(user: user),
                            ),
                          );
                        },
                      );
                    },
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
                    Center(child: Text('Failed to load users')),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppSearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;

  const _AppSearchField({
    required this.controller,
    required this.hintText,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hintText,
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surface,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(999),
            borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(999),
            borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
          ),
        ),
        onChanged: onChanged,
      ),
    );
  }
}
