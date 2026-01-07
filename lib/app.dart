import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_routes.dart';
import 'core/theme/app_theme.dart';
import 'features/splash/splash_page.dart';
import 'features/auth/login_page.dart';
import 'features/dashboard/dashboard_page.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),

      initialRoute: AppRoutes.splash,

      routes: {
        AppRoutes.splash: (_) => const SplashPage(),
        AppRoutes.login: (_) => const LoginPage(),
        AppRoutes.dashboard: (_) => const DashboardPage(),
      },
    );
  }
}
