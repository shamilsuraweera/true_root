import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/widgets/adaptive_shell.dart';

import '../home/home_page.dart';
import '../batches/batch_list_page.dart';
import '../profile/profile_page.dart';
import '../users/users_page.dart';
import 'state/dashboard_tab_provider.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  final List<GlobalKey<NavigatorState>> _navigatorKeys = [
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
  ];

  late final List<Widget> _pages = [
    _TabNavigator(navigatorKey: _navigatorKeys[0], child: const HomePage()),
    _TabNavigator(
      navigatorKey: _navigatorKeys[1],
      child: const BatchListPage(),
    ),
    _TabNavigator(navigatorKey: _navigatorKeys[2], child: const UsersPage()),
    _TabNavigator(navigatorKey: _navigatorKeys[3], child: const ProfilePage()),
  ];

  @override
  Widget build(BuildContext context) {
    final index = ref.watch(dashboardTabProvider);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        final currentNavigator = _navigatorKeys[index].currentState;
        if (currentNavigator != null && currentNavigator.canPop()) {
          currentNavigator.pop();
          return;
        }
        if (index != 0) {
          ref.read(dashboardTabProvider.notifier).state = 0;
        } else {
          Navigator.of(context).maybePop();
        }
      },
      child: AdaptiveShell(
        destinations: _destinations,
        selectedIndex: index,
        onSelected: (i) {
          if (i == index) {
            _navigatorKeys[i].currentState?.popUntil((r) => r.isFirst);
          } else {
            ref.read(dashboardTabProvider.notifier).state = i;
          }
        },
        body: IndexedStack(index: index, children: _pages),
      ),
    );
  }
}

const _destinations = [
  ShellDestination(
    label: 'Dashboard',
    icon: Icons.space_dashboard_outlined,
    selectedIcon: Icons.space_dashboard_rounded,
  ),
  ShellDestination(
    label: 'Batches',
    icon: Icons.inventory_2_outlined,
    selectedIcon: Icons.inventory_2_rounded,
  ),
  ShellDestination(
    label: 'Users',
    icon: Icons.people_outline_rounded,
    selectedIcon: Icons.people_rounded,
  ),
  ShellDestination(
    label: 'Profile',
    icon: Icons.person_outline_rounded,
    selectedIcon: Icons.person_rounded,
  ),
];

class _TabNavigator extends StatelessWidget {
  final GlobalKey<NavigatorState> navigatorKey;
  final Widget child;

  const _TabNavigator({required this.navigatorKey, required this.child});

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKey,
      onGenerateRoute: (settings) {
        return MaterialPageRoute(builder: (_) => child);
      },
    );
  }
}
