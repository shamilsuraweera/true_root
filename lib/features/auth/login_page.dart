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
            ref.read(authProvider.notifier).login();
            Navigator.pushReplacementNamed(context, AppRoutes.home);
          },
          child: const Text('Login (Mock)'),
        ),
      ),
    );
  }
}
