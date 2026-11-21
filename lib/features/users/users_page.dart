import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/widgets/app_widgets.dart';
import 'state/users_provider.dart';
import 'user_detail_page.dart';
import 'models/user.dart';
import '../notifications/notifications_sheet.dart';

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
    final cachedUsers = ref.watch(cachedUsersListProvider);

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              MediaQuery.paddingOf(context).top + 12,
              16,
              18,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: AppSearchField(
                        controller: _searchController,
                        hint: 'Search users',
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton.filledTonal(
                      icon: const Icon(Icons.notifications_none_rounded),
                      tooltip: 'Notifications',
                      onPressed: () => showNotificationsSheet(context, ref),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  'People in your network',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  'Browse and verify users involved in your supply chain.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ContentWidth(
              child: RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(usersListProvider);
                  await ref.read(usersListProvider.future);
                },
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
                          EmptyState(
                            icon: Icons.people_outline_rounded,
                            title: 'No users found',
                          ),
                        ],
                      );
                    }
                    return ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      itemCount: filtered.length,
                      separatorBuilder: (context, _) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final user = filtered[index];
                        return _UserCard(
                          user: user,
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
                  error: (_, _) {
                    if (cachedUsers.isNotEmpty) {
                      final query = _searchController.text.trim().toLowerCase();
                      final filtered = query.isEmpty
                          ? cachedUsers
                          : cachedUsers
                                .where((user) => user.matches(query))
                                .toList();
                      return ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                        itemCount: filtered.length,
                        separatorBuilder: (context, _) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final user = filtered[index];
                          return _UserCard(
                            user: user,
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
                    }
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        const SizedBox(height: 200),
                        const Center(child: Text('Failed to load users')),
                        TextButton(
                          onPressed: () => ref.invalidate(usersListProvider),
                          child: const Text('Retry'),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final AppUser user;
  final VoidCallback onTap;

  const _UserCard({required this.user, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final initial = user.displayName.isNotEmpty
        ? user.displayName[0].toUpperCase()
        : '?';
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: colorScheme.primaryContainer,
            foregroundColor: colorScheme.onPrimaryContainer,
            child: Text(initial),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.displayName,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  '${user.organizationLabel} • ${user.roleLabel} • ${user.locationLabel}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
    );
  }
}
