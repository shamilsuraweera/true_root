import 'package:flutter/material.dart';

import 'features/splash/splash_page.dart';
import 'features/auth/login_page.dart';
import 'features/auth/register_page.dart';
import 'features/dashboard/dashboard_page.dart';
import 'features/admin/admin_guard_page.dart';

class AppRoutes {
  // Route names
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String dashboard = '/dashboard';
  static const String admin = '/admin';

  // Central route map
  static final Map<String, WidgetBuilder> routes = {
    splash: (_) => const SplashPage(),
    login: (_) => const LoginPage(),
    register: (_) => const RegisterPage(),
    dashboard: (_) => const DashboardPage(),
    admin: (_) => const AdminGuardPage(),
  };
}
