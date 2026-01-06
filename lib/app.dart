import 'package:flutter/material.dart';
import 'app_routes.dart';
import 'core/theme/app_theme.dart';

class TrueRootApp extends StatelessWidget {
  const TrueRootApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'True Root',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      initialRoute: AppRoutes.splash,
      routes: AppRoutes.routes,
    );
  }
}
