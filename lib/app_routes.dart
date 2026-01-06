import 'package:flutter/material.dart';
import 'features/splash/splash_page.dart';
import 'features/auth/login_page.dart';
import 'features/home/home_page.dart';

class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const home = '/home';

  static final Map<String, WidgetBuilder> routes = {
    splash: (_) => const SplashPage(),
    login: (_) => const LoginPage(),
    home: (_) => const HomePage(),
  };
}
