import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../state/auth_state.dart';
import '../auth/state/auth_provider.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _bootstrap();
    });
  }

  Future<void> _bootstrap() async {
    if (kIsWeb) {
      final fragment = Uri.base.fragment;
      if (fragment.startsWith('/admin')) {
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, AppRoutes.admin);
        return;
      }
    }

    final authState = ref.read(authProvider);
    if (!authState.isLoggedIn) {
      final storage = ref.read(authStorageProvider);
      final saved = await storage.loadActiveAccount();
      if (saved != null &&
          saved.accessToken != null &&
          saved.accessToken!.isNotEmpty &&
          saved.userId != null &&
          saved.role != null) {
        ref.read(authProvider.notifier).login(
              userId: saved.userId!,
              role: parseUserRole(saved.role),
              email: saved.email,
              accessToken: saved.accessToken!,
            );
      }
    }

    if (!mounted) return;
    final isLoggedIn = ref.read(authProvider).isLoggedIn;
    Navigator.pushReplacementNamed(
      context,
      isLoggedIn ? AppRoutes.dashboard : AppRoutes.login,
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Image(
          image: AssetImage('assets/icon/app_icon.png'),
          width: 120,
          height: 120,
        ),
      ),
    );
  }
}
