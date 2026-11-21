import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';
import 'brand_logo.dart';

class ShellDestination {
  const ShellDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });
  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

/// Responsive navigation scaffold:
/// * < 700px   : floating M3 NavigationBar at the bottom
/// * 700-1100  : compact NavigationRail
/// * >= 1100   : extended sidebar with brand lockup
class AdaptiveShell extends StatelessWidget {
  const AdaptiveShell({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
    required this.body,
    this.trailing,
    this.appBar,
  });

  final List<ShellDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final Widget body;
  final Widget? trailing;
  final PreferredSizeWidget? appBar;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final c = Theme.of(context).colorScheme;

    if (width < Breakpoints.tablet) {
      return Scaffold(
        appBar: appBar,
        body: body,
        bottomNavigationBar: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(Gap.lg, 0, Gap.lg, Gap.md),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: Radii.xlAll,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: Theme.of(context).brightness == Brightness.dark
                          ? 0.4
                          : 0.12,
                    ),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: Radii.xlAll,
                child: NavigationBar(
                  selectedIndex: selectedIndex,
                  onDestinationSelected: onSelected,
                  labelBehavior:
                      NavigationDestinationLabelBehavior.onlyShowSelected,
                  destinations: [
                    for (final d in destinations)
                      NavigationDestination(
                        icon: Icon(d.icon),
                        selectedIcon: Icon(d.selectedIcon),
                        label: d.label,
                        tooltip: d.label,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    final extended = width >= Breakpoints.desktop;
    return Scaffold(
      appBar: appBar,
      body: Row(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: c.surface,
              border: Border(right: BorderSide(color: c.outline)),
            ),
            child: SafeArea(
              child: NavigationRail(
                extended: extended,
                minExtendedWidth: 232,
                selectedIndex: selectedIndex,
                onDestinationSelected: onSelected,
                labelType: extended ? null : NavigationRailLabelType.all,
                leading: Padding(
                  padding: const EdgeInsets.symmetric(vertical: Gap.xl),
                  child: extended
                      ? const BrandLogo(size: 36, showWordmark: true)
                      : const BrandLogo(size: 40),
                ),
                trailing: trailing == null
                    ? null
                    : Expanded(
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: Gap.lg),
                            child: trailing,
                          ),
                        ),
                      ),
                destinations: [
                  for (final d in destinations)
                    NavigationRailDestination(
                      icon: Icon(d.icon),
                      selectedIcon: Icon(d.selectedIcon),
                      label: Text(d.label),
                      padding: const EdgeInsets.symmetric(vertical: 2),
                    ),
                ],
              ),
            ),
          ),
          Expanded(child: body),
        ],
      ),
    );
  }
}
