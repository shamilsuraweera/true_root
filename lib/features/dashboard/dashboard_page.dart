import 'package:flutter/material.dart';

import '../home/home_page.dart';
import '../batches/batch_list_page.dart';
import '../profile/profile_page.dart';
import '../users/users_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _index = 0;

  final List<GlobalKey<NavigatorState>> _navigatorKeys = [
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
  ];

  late final List<Widget> _pages = [
    _TabNavigator(
      navigatorKey: _navigatorKeys[0],
      child: const HomePage(),
    ),
    _TabNavigator(
      navigatorKey: _navigatorKeys[1],
      child: const BatchListPage(),
    ),
    _TabNavigator(
      navigatorKey: _navigatorKeys[2],
      child: const UsersPage(),
    ),
    _TabNavigator(
      navigatorKey: _navigatorKeys[3],
      child: const ProfilePage(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        final currentNavigator = _navigatorKeys[_index].currentState;
        if (currentNavigator != null && currentNavigator.canPop()) {
          currentNavigator.pop();
          return;
        }
        if (_index != 0) {
          setState(() => _index = 0);
        } else {
          Navigator.of(context).maybePop();
        }
      },
      child: Scaffold(
        body: IndexedStack(index: _index, children: _pages),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _index,
          onTap: (i) {
            if (i == _index) {
              _navigatorKeys[i].currentState?.popUntil((route) => route.isFirst);
            } else {
              setState(() => _index = i);
            }
          },
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Dashboard'),
            BottomNavigationBarItem(
              icon: Icon(Icons.inventory_2),
              label: 'Batches',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Users'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}

class _TabNavigator extends StatelessWidget {
  final GlobalKey<NavigatorState> navigatorKey;
  final Widget child;

  const _TabNavigator({
    required this.navigatorKey,
    required this.child,
  });

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
