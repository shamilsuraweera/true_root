import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

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
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        final isDark = theme.brightness == Brightness.dark;
        final navBackground = isDark ? colorScheme.surface : Colors.white;
        final unselectedColor = isDark
            ? colorScheme.onSurface.withValues(alpha: 0.72)
            : AppColors.textMuted;

        return Scaffold(
          body: Row(
            children: [
              if (isWide)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 0, 24),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: navBackground,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: isDark ? 0.35 : 0.13,
                          ),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: NavigationRail(
                        backgroundColor: navBackground,
                        selectedIndex: _index,
                        onDestinationSelected: (value) =>
                            setState(() => _index = value),
                        labelType: NavigationRailLabelType.all,
                        leading: Padding(
                          padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Image.asset(
                                'assets/icon/app_icon.png',
                                width: 28,
                                height: 28,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.eco, size: 24),
                              ),
                              const SizedBox(width: 8),
                              const Text('Admin'),
                            ],
                          ),
                        ),
                        selectedIconTheme: const IconThemeData(
                          color: AppColors.primary,
                        ),
                        unselectedIconTheme: IconThemeData(
                          color: unselectedColor,
                        ),
                        selectedLabelTextStyle: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                        unselectedLabelTextStyle: TextStyle(
                          color: unselectedColor,
                        ),
                        destinations: [
                          for (final destination in _destinations)
                            NavigationRailDestination(
                              icon: Icon(destination.icon),
                              label: Text(destination.label),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              Expanded(child: _AdminContent(index: _index)),
            ],
          ),
          bottomNavigationBar: isWide
              ? null
              : SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: navBackground,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: isDark ? 0.35 : 0.13,
                            ),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: BottomNavigationBar(
                          currentIndex: _index,
                          onTap: (value) => setState(() => _index = value),
                          type: BottomNavigationBarType.fixed,
                          backgroundColor: navBackground,
                          selectedItemColor: AppColors.primary,
                          unselectedItemColor: unselectedColor,
                          showUnselectedLabels: true,
                          items: [
                            for (final destination in _destinations)
                              BottomNavigationBarItem(
                                icon: Icon(destination.icon),
                                label: destination.label,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
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
