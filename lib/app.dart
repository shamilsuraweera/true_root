import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/splash/splash_page.dart';

class TrueRootApp extends StatelessWidget {
  const TrueRootApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'True Root',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const SplashPage(),
    );
  }
}
