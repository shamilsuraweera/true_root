import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app_routes.dart';
import '../../state/auth_state.dart';
import 'admin_shell_page.dart';

class AdminGuardPage extends ConsumerWidget {
  const AdminGuardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    if (!auth.isLoggedIn) {
      return _GateScaffold(
        title: 'Admin Login Required',
        message: 'Please sign in with an admin account to continue.',
        actionLabel: 'Go to login',
        onAction: () => Navigator.pushReplacementNamed(context, AppRoutes.login),
      );
    }

    if (auth.role != UserRole.admin) {
      return const _GateScaffold(
        title: 'Admin Only',
        message: 'Your account does not have admin access.',
      );
    }

    return const AdminShellPage();
  }
}

class _GateScaffold extends StatelessWidget {
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _GateScaffold({
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(message, textAlign: TextAlign.center),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: onAction,
                  child: Text(actionLabel!),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
