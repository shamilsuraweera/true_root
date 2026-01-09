import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app_routes.dart';
import '../../state/auth_state.dart';

class LoginPage extends ConsumerWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            // DEV MODE: force login
            ref.read(authProvider.notifier).login(role: UserRole.admin);

            Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
          },
          child: const Text('Login (DEV MODE)'),
        ),
      ),
    );
  }
}
