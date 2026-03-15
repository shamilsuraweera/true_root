import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class AdminPageShell extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? searchField;
  final List<Widget> actions;
  final Widget child;

  const AdminPageShell({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.searchField,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final headerBackground = isDark ? colorScheme.surface : AppColors.primary;
    final contentBackground = isDark
        ? theme.scaffoldBackgroundColor
        : AppColors.background;
    final titleColor = isDark ? colorScheme.onSurface : Colors.white;
    final subtitleColor = isDark
        ? colorScheme.onSurface.withValues(alpha: 0.82)
        : Colors.white.withValues(alpha: 0.9);

    return ColoredBox(
      color: headerBackground,
      child: Column(
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
                    if (searchField != null) Expanded(child: searchField!),
                    if (searchField != null && actions.isNotEmpty)
                      const SizedBox(width: 10),
                    ...actions,
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  title,
                  style: TextStyle(
                    color: titleColor,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: TextStyle(color: subtitleColor, fontSize: 14),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: contentBackground,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

class AdminHeaderSearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;

  const AdminHeaderSearchField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SizedBox(
      height: 44,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hintText,
          prefixIcon: Icon(
            Icons.search,
            color: isDark
                ? theme.colorScheme.onSurface.withValues(alpha: 0.85)
                : Colors.white,
          ),
          filled: true,
          fillColor: isDark
              ? theme.colorScheme.onSurface.withValues(alpha: 0.08)
              : Colors.white.withValues(alpha: 0.18),
          hintStyle: TextStyle(
            color: isDark
                ? theme.colorScheme.onSurface.withValues(alpha: 0.72)
                : Colors.white.withValues(alpha: 0.85),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(999),
            borderSide: BorderSide(
              color: isDark
                  ? theme.colorScheme.onSurface.withValues(alpha: 0.14)
                  : Colors.white.withValues(alpha: 0.25),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(999),
            borderSide: BorderSide(
              color: isDark
                  ? theme.colorScheme.onSurface.withValues(alpha: 0.14)
                  : Colors.white.withValues(alpha: 0.25),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(999),
            borderSide: BorderSide(
              color: isDark ? theme.colorScheme.onSurface : Colors.white,
              width: 1.4,
            ),
          ),
        ),
      ),
    );
  }
}

class AdminHeaderIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const AdminHeaderIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: isDark
          ? theme.colorScheme.onSurface.withValues(alpha: 0.12)
          : Colors.white.withValues(alpha: 0.2),
      shape: const CircleBorder(),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(
          icon,
          color: isDark ? theme.colorScheme.onSurface : Colors.white,
        ),
      ),
    );
  }
}
