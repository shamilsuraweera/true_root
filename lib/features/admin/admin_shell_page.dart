import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_tokens.dart';
import '../../core/widgets/adaptive_shell.dart';
import '../../core/widgets/brand_logo.dart';
import '../../app_routes.dart';
import '../../state/auth_state.dart';

import 'admin_dashboard_page.dart';
import 'admin_batches_page.dart';
import 'admin_products_page.dart';
import 'admin_stages_page.dart';
import 'admin_users_page.dart';

class AdminShellPage extends ConsumerStatefulWidget {
  const AdminShellPage({super.key});

  @override
  ConsumerState<AdminShellPage> createState() => _AdminShellPageState();
}

class _AdminShellPageState extends ConsumerState<AdminShellPage> {
  int _index = 0;

  static const _destinations = [
    ShellDestination(
      label: 'Dashboard',
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard_rounded,
    ),
    ShellDestination(
      label: 'Users',
      icon: Icons.people_outline_rounded,
      selectedIcon: Icons.people_rounded,
    ),
    ShellDestination(
      label: 'Products',
      icon: Icons.inventory_2_outlined,
      selectedIcon: Icons.inventory_2_rounded,
    ),
    ShellDestination(
      label: 'Stages',
      icon: Icons.timeline_rounded,
      selectedIcon: Icons.timeline_rounded,
    ),
    ShellDestination(
      label: 'Batches',
      icon: Icons.local_shipping_outlined,
      selectedIcon: Icons.local_shipping_rounded,
    ),
  ];

  void _switchToUserView() => Navigator.pushNamed(context, AppRoutes.dashboard);

  void _signOut() {
    ref.read(authProvider.notifier).logout();
    Navigator.pushReplacementNamed(context, AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < Breakpoints.tablet;
    return AdaptiveShell(
      destinations: _destinations,
      selectedIndex: _index,
      onSelected: (value) => setState(() => _index = value),
      appBar: compact
          ? AppBar(
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const BrandLogo(size: 28),
                  const SizedBox(width: Gap.sm),
                  Text('Admin · ${_destinations[_index].label}'),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.swap_horiz_rounded),
                  tooltip: 'Switch to User View',
                  onPressed: _switchToUserView,
                ),
                IconButton(
                  icon: const Icon(Icons.logout_rounded),
                  tooltip: 'Sign Out',
                  onPressed: _signOut,
                ),
              ],
            )
          : null,
      trailing: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.swap_horiz_rounded),
            tooltip: 'Switch to User View',
            onPressed: _switchToUserView,
          ),
          const SizedBox(height: Gap.sm),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Sign Out',
            onPressed: _signOut,
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: Motion.base,
        switchInCurve: Motion.curve,
        child: KeyedSubtree(
          key: ValueKey(_index),
          child: _AdminContent(index: _index),
        ),
      ),
    );
  }
}

class _AdminContent extends StatelessWidget {
  final int index;

  const _AdminContent({required this.index});

  @override
  Widget build(BuildContext context) {
    if (index == 0) {
      return const AdminDashboardPage();
    }
    if (index == 1) {
      return const AdminUsersPage();
    }
    if (index == 2) {
      return const AdminProductsPage();
    }
    if (index == 3) {
      return const AdminStagesPage();
    }
    return const AdminBatchesPage();
  }
}
