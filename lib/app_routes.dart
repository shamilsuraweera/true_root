import 'package:flutter/material.dart';

import 'features/splash/splash_page.dart';
import 'features/auth/login_page.dart';
import 'features/dashboard/dashboard_page.dart';

class AppRoutes {
  // Route names
  static const String splash = '/';
  static const String login = '/login';
  static const String dashboard = '/dashboard';

  // Central route map
  static final Map<String, WidgetBuilder> routes = {
    splash: (_) => const SplashPage(),
    login: (_) => const LoginPage(),
    dashboard: (_) => const DashboardPage(),
  };
}
