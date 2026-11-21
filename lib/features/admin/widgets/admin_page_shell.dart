import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_widgets.dart';

/// Shared header + content layout for admin pages.
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
    final t = Theme.of(context).textTheme;
    final c = Theme.of(context).colorScheme;
    final compact = Breakpoints.isCompact(context);
    final hasToolbar = searchField != null || actions.isNotEmpty;

    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: ContentWidth(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                Gap.lg,
                compact ? Gap.sm : MediaQuery.paddingOf(context).top + Gap.xl,
                Gap.lg,
                Gap.lg,
              ),
              child: FadeSlideIn(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: t.headlineMedium),
                    const SizedBox(height: Gap.xs),
                    Text(
                      subtitle,
                      style: t.bodyMedium?.copyWith(color: c.onSurfaceVariant),
                    ),
                    if (hasToolbar) ...[
                      const SizedBox(height: Gap.lg),
                      Row(
                        children: [
                          if (searchField != null) Expanded(child: searchField!),
                          if (searchField != null && actions.isNotEmpty)
                            const SizedBox(width: Gap.md),
                          ...actions,
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Expanded(child: child),
          ],
        ),
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
  Widget build(BuildContext context) => AppSearchField(
        controller: controller,
        hint: hintText,
        onChanged: onChanged,
      );
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
  Widget build(BuildContext context) => IconButton.filled(
        onPressed: onPressed,
        icon: Icon(icon),
        style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
      );
}
