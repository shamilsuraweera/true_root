import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final headerBackground = isDark ? colorScheme.surface : AppColors.primary;
    final contentBackground = isDark
        ? theme.scaffoldBackgroundColor
        : AppColors.background;
    final headerIconBackground = isDark
        ? colorScheme.onSurface.withValues(alpha: 0.12)
        : Colors.white.withValues(alpha: 0.2);
    final headerTitleColor = isDark ? colorScheme.onSurface : Colors.white;
    final headerSubtitleColor = isDark
        ? colorScheme.onSurface.withValues(alpha: 0.82)
        : Colors.white.withValues(alpha: 0.9);

    final usersAsync = ref.watch(usersListProvider);
    final cachedUsers = ref.watch(cachedUsersListProvider);

    return Scaffold(
      backgroundColor: headerBackground,
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
                      child: _AppSearchField(
                        controller: _searchController,
                        hintText: 'Search users',
                        onChanged: (_) => setState(() {}),
                        useLightStyle: !isDark,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Material(
                      color: headerIconBackground,
                      shape: const CircleBorder(),
                      child: IconButton(
                        icon: Icon(
                          Icons.notifications_none,
                          color: headerTitleColor,
                        ),
                        onPressed: () {
                          showNotificationsSheet(context, ref);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  'People in your network',
                  style: TextStyle(
                    color: headerTitleColor,
                    fontSize: 23,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Browse and verify users involved in your supply chain.',
                  style: TextStyle(color: headerSubtitleColor, fontSize: 14),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: contentBackground,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),
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
                          Center(child: Text('No users found')),
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

class _AppSearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;
  final bool useLightStyle;

  const _AppSearchField({
    required this.controller,
    required this.hintText,
    required this.onChanged,
    this.useLightStyle = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hintText,
          prefixIcon: Icon(
            Icons.search,
            color: useLightStyle ? Colors.white.withValues(alpha: 0.9) : null,
          ),
          filled: true,
          fillColor: useLightStyle
              ? Colors.white.withValues(alpha: 0.18)
              : Theme.of(context).colorScheme.surface,
          hintStyle: useLightStyle
              ? TextStyle(color: Colors.white.withValues(alpha: 0.85))
              : null,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(999),
            borderSide: BorderSide(
              color: useLightStyle
                  ? Colors.white.withValues(alpha: 0.25)
                  : Theme.of(context).colorScheme.outline,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(999),
            borderSide: BorderSide(
              color: useLightStyle
                  ? Colors.white.withValues(alpha: 0.25)
                  : Theme.of(context).colorScheme.outline,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(999),
            borderSide: BorderSide(
              color: useLightStyle
                  ? Colors.white
                  : Theme.of(context).colorScheme.primary,
              width: 1.4,
            ),
          ),
        ),
        onChanged: onChanged,
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
    return Material(
      color: colorScheme.surface,
      elevation: 0.6,
      borderRadius: BorderRadius.circular(16),
      shadowColor: colorScheme.shadow.withValues(alpha: 0.12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
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
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
