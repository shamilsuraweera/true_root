import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app_routes.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/app_widgets.dart';
import '../../state/auth_state.dart';
import '../auth/state/auth_provider.dart';
import '../users/models/user.dart';
import '../users/state/users_provider.dart';
import 'state/profile_provider.dart';
import '../../state/theme_state.dart';
import '../notifications/notifications_sheet.dart';

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
  static const List<String> _accountTypeOptions = ['Individual', 'Company'];
  final List<String> _members = [];
  final _memberController = TextEditingController();
  final _searchController = TextEditingController();
  String _searchQuery = '';
  bool _initialized = false;

  @override
  void dispose() {
    _nameController.dispose();
    _orgController.dispose();
    _locationController.dispose();
    _memberController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);
    final cachedProfile = ref.watch(cachedProfileProvider);
    final usersAsync = ref.watch(usersListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            tooltip: 'Notifications',
            icon: const Icon(Icons.notifications_none_rounded),
            onPressed: () => showNotificationsSheet(context, ref),
          ),
          IconButton(
            tooltip: 'Toggle theme',
            icon: AnimatedSwitcher(
              duration: Motion.base,
              child: Icon(
                Theme.of(context).brightness == Brightness.dark
                    ? Icons.light_mode_rounded
                    : Icons.dark_mode_rounded,
                key: ValueKey(Theme.of(context).brightness),
              ),
            ),
            onPressed: () => ref.read(themeModeProvider.notifier).toggle(),
          ),
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout_rounded),
            onPressed: _logout,
          ),
          const SizedBox(width: Gap.sm),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: profileAsync.when(
          data: (profile) {
            final auth = ref.watch(authProvider);
            if (!_initialized) {
              _nameController.text = profile.name ?? '';
              _orgController.text = profile.organization ?? '';
              _locationController.text = profile.location ?? '';
              final nextType = profile.accountType ?? 'Individual';
              _accountType = _accountTypeOptions.contains(nextType)
                  ? nextType
                  : 'Individual';
              _members
                ..clear()
                ..addAll(profile.members);
              _initialized = true;
            }

            final visibleMembers = _searchQuery.isEmpty
                ? _members
                : _members
                      .where(
                        (member) => member.toLowerCase().contains(_searchQuery),
                      )
                      .toList();

            return Form(
              key: _formKey,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  Gap.lg,
                  Gap.sm,
                  Gap.lg,
                  MediaQuery.sizeOf(context).width < Breakpoints.tablet
                      ? 120
                      : Gap.xxl,
                ),
                children: [
                  _ProfileHeader(
                    name: _nameController.text.isNotEmpty
                        ? _nameController.text
                        : (profile.name ?? 'Your profile'),
                    subtitle: [
                      auth.role?.name ?? "",
                      if ((profile.organization ?? '').isNotEmpty)
                        profile.organization!,
                    ].where((e) => e.isNotEmpty).join(' · '),
                  ),
                  const SizedBox(height: Gap.xl),
                  if (auth.role == UserRole.admin) ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(0, 52),
                        ),
                        icon: const Icon(Icons.admin_panel_settings),
                        label: const Text(
                          'Open Admin Console',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        onPressed: () {
                          Navigator.pushNamed(context, AppRoutes.admin);
                        },
                      ),
                    ),
                  ],
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Name'),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Required'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _orgController,
                    decoration: const InputDecoration(
                      labelText: 'Organization',
                    ),
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
                      DropdownMenuItem(
                        value: 'Individual',
                        child: Text('Individual'),
                      ),
                      DropdownMenuItem(
                        value: 'Company',
                        child: Text('Company'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _accountType = value);
                    },
                    decoration: const InputDecoration(
                      labelText: 'Account Type',
                    ),
                  ),
                  if (_accountType == 'Company') ...[
                    const SizedBox(height: 16),
                    Text(
                      'Members',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    AppSearchField(
                      hint: 'Search members',
                      controller: _searchController,
                      onChanged: (value) => setState(
                        () => _searchQuery = value.trim().toLowerCase(),
                      ),
                    ),
                    const SizedBox(height: Gap.md),
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
                    if (visibleMembers.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text('No matching members'),
                      )
                    else
                      ...visibleMembers.map(
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
                  if (kIsWeb && auth.role == UserRole.admin) ...[
                    OutlinedButton.icon(
                      onPressed: () => Navigator.of(
                        context,
                        rootNavigator: true,
                      ).pushNamed(AppRoutes.admin),
                      icon: const Icon(Icons.admin_panel_settings_outlined),
                      label: const Text('Open Admin Panel'),
                    ),
                    const SizedBox(height: 12),
                  ],
                  PrimaryButton(
                    label: 'Save changes',
                    icon: Icons.check_rounded,
                    onPressed: () => _save(profile.id),
                  ),
                ],
              ),
            );
          },
          loading: () => const LoadingList(count: 3),
          error: (_, _) {
            if (cachedProfile != null) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  const Text('Offline: showing cached profile'),
                  const SizedBox(height: 16),
                  _ProfileInfoRow(
                    label: 'Name',
                    value: cachedProfile.displayName,
                  ),
                  _ProfileInfoRow(label: 'Email', value: cachedProfile.email),
                  _ProfileInfoRow(
                    label: 'Organization',
                    value: cachedProfile.organizationLabel,
                  ),
                  _ProfileInfoRow(
                    label: 'Location',
                    value: cachedProfile.locationLabel,
                  ),
                  _ProfileInfoRow(
                    label: 'Account Type',
                    value: cachedProfile.accountType ?? 'Individual',
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => ref.invalidate(profileProvider),
                    child: const Text('Retry'),
                  ),
                ],
              );
            }
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const SizedBox(height: 200),
                const Center(child: Text('Failed to load profile')),
                TextButton(
                  onPressed: () => ref.invalidate(profileProvider),
                  child: const Text('Retry'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _addMember(AsyncValue<List<AppUser>> usersAsync) {
    final value = _memberController.text.trim();
    if (value.isEmpty) return;
    final users = usersAsync.value ?? [];
    final exists = users.any(
      (user) => user.email.toLowerCase() == value.toLowerCase(),
    );
    if (!exists) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('User not found')));
      return;
    }
    if (_members.contains(value)) {
      _memberController.clear();
      return;
    }
    setState(() {
      _members.add(value);
      _accountType = 'Company';
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
      final hasMembers = _members.isNotEmpty;
      if (hasMembers && _orgController.text.trim().isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Organization is required for Company profiles'),
          ),
        );
        return;
      }
      final accountTypeToSave = hasMembers ? 'Company' : _accountType;
      if (hasMembers && _accountType != 'Company') {
        setState(() => _accountType = 'Company');
      }
      await api.updateUser(userId, {
        'name': _nameController.text.trim(),
        'organization': _orgController.text.trim(),
        'location': _locationController.text.trim(),
        'accountType': accountTypeToSave,
        'members': hasMembers ? _members : [],
      });
      setState(() => _initialized = false);
      ref.invalidate(profileProvider);
      await ref.read(profileProvider.future);
      ref.invalidate(usersListProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile updated')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to save profile')));
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
    Navigator.of(
      context,
      rootNavigator: true,
    ).pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
  }
}

class _ProfileInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _ProfileInfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(width: 120, child: Text(label)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.name, required this.subtitle});
  final String name;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
    return Container(
      padding: const EdgeInsets.all(Gap.xl),
      decoration: BoxDecoration(
        gradient: AppGradients.brand,
        borderRadius: Radii.xlAll,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            child: Text(
              initial,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: Gap.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
