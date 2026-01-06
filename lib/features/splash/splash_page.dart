import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app_routes.dart';
import '../../state/auth_state.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(seconds: 1), () {
      final isLoggedIn = ref.read(authProvider).isLoggedIn;

      Navigator.pushReplacementNamed(
        context,
        isLoggedIn ? AppRoutes.home : AppRoutes.login,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('True Root', style: TextStyle(fontSize: 24))),
    );
  }
}
