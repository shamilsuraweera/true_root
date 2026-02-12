import 'package:flutter/material.dart';

import 'admin_dashboard_page.dart';
import 'admin_batches_page.dart';
import 'admin_products_page.dart';
import 'admin_stages_page.dart';
import 'admin_users_page.dart';

class AdminShellPage extends StatefulWidget {
  const AdminShellPage({super.key});

  @override
  State<AdminShellPage> createState() => _AdminShellPageState();
}

class _AdminShellPageState extends State<AdminShellPage> {
  int _index = 0;

  final _destinations = const [
    _AdminDestination(label: 'Dashboard', icon: Icons.dashboard),
    _AdminDestination(label: 'Users', icon: Icons.people),
    _AdminDestination(label: 'Products', icon: Icons.inventory_2),
    _AdminDestination(label: 'Stages', icon: Icons.timeline),
    _AdminDestination(label: 'Batches', icon: Icons.local_shipping),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;
        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                Image.asset(
                  'assets/icon/app_icon.png',
                  width: 28,
                  height: 28,
                  errorBuilder: (context, _, _) =>
                      const Icon(Icons.eco, size: 24),
                ),
                const SizedBox(width: 8),
                const Text('Admin'),
              ],
            ),
          ),
          body: Row(
            children: [
              if (isWide)
                NavigationRail(
                  selectedIndex: _index,
                  onDestinationSelected: (value) =>
                      setState(() => _index = value),
                  labelType: NavigationRailLabelType.all,
                  destinations: [
                    for (final destination in _destinations)
                      NavigationRailDestination(
                        icon: Icon(destination.icon),
                        label: Text(destination.label),
                      ),
                  ],
                ),
              Expanded(child: _AdminContent(index: _index)),
            ],
          ),
          bottomNavigationBar: isWide
              ? null
              : BottomNavigationBar(
                  currentIndex: _index,
                  onTap: (value) => setState(() => _index = value),
                  items: [
                    for (final destination in _destinations)
                      BottomNavigationBarItem(
                        icon: Icon(destination.icon),
                        label: destination.label,
                      ),
                  ],
                ),
        );
      },
    );
  }
}

class _AdminDestination {
  final String label;
  final IconData icon;

  const _AdminDestination({required this.label, required this.icon});
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
