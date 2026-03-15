import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';

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
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final navBackground = isDark ? colorScheme.surface : Colors.white;
    final unselected = isDark
        ? colorScheme.onSurface.withValues(alpha: 0.7)
        : AppColors.textMuted;

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
      child: Scaffold(
        body: IndexedStack(index: index, children: _pages),
        bottomNavigationBar: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: navBackground,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.13),
                    blurRadius: 16,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Theme(
                  data: Theme.of(context).copyWith(
                    splashFactory: NoSplash.splashFactory,
                    highlightColor: Colors.transparent,
                    splashColor: Colors.transparent,
                  ),
                  child: BottomNavigationBar(
                    currentIndex: index,
                    onTap: (i) {
                      if (i == index) {
                        _navigatorKeys[i].currentState?.popUntil(
                          (route) => route.isFirst,
                        );
                      } else {
                        ref.read(dashboardTabProvider.notifier).state = i;
                      }
                    },
                    type: BottomNavigationBarType.fixed,
                    backgroundColor: navBackground,
                    selectedItemColor: AppColors.primary,
                    unselectedItemColor: unselected,
                    showUnselectedLabels: true,
                    items: const [
                      BottomNavigationBarItem(
                        icon: Icon(Icons.home_filled),
                        label: 'Dashboard',
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(Icons.inventory_2_outlined),
                        label: 'Batches',
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(Icons.people_outline),
                        label: 'Users',
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(Icons.person_outline),
                        label: 'Profile',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

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
