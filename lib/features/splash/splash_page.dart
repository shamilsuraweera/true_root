import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app_routes.dart';
import '../../state/auth_state.dart';
import '../../core/theme/app_colors.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(seconds: 1), _handleNavigation);
  }

  void _handleNavigation() {
    if (!mounted) return;

    final auth = ref.read(authProvider);

    if (!auth.isLoggedIn) {
      Navigator.pushReplacementNamed(context, AppRoutes.login);
      return;
    }

    // Role-based redirect (expand later if needed)
    switch (auth.role) {
      case UserRole.admin:
      case UserRole.operator:
        Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
        break;
      default:
        Navigator.pushReplacementNamed(context, AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Image.asset(
          'assets/icon/app_icon.png',
          width: 140,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
