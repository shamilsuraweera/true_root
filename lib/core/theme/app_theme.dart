import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary = Color(0xFF007E6E);
  static const Color secondary = Color(0xFF73AF6F);
  static const Color background = Color(0xFFE7DEAF);
  static const Color accent = Color(0xFFD7C097);
  static const Color textDark = Color(0xFF1E1E1E);

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: background,

      colorScheme: ColorScheme.light(
        primary: primary,
        secondary: secondary,
        surface: background,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textDark,
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: background,
        selectedItemColor: primary,
        unselectedItemColor: Color(0xFF6B6B6B),
        selectedIconTheme: IconThemeData(size: 26),
        unselectedIconTheme: IconThemeData(size: 24),
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: primary,
        foregroundColor: Colors.white,
      ),
    );
  }
}
