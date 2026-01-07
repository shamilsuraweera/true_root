import 'package:flutter/material.dart';
import 'features/splash/splash_page.dart';
import 'features/auth/login_page.dart';
import 'features/dashboard/dashboard_page.dart';

class AppRoutes {
  static const splash = '/splash';
  static const login = '/login';
  static const dashboard = '/dashboard';

  static Map<String, WidgetBuilder> get routes => {
    splash: (_) => const SplashPage(),
    login: (_) => const LoginPage(),
    dashboard: (_) => const DashboardPage(),
  };
}
