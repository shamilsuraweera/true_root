import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'app_tokens.dart';

class AppTheme {
  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final dark = brightness == Brightness.dark;

    final bg = dark ? AppColors.darkBackground : AppColors.background;
    final surface = dark ? AppColors.darkSurface : AppColors.surface;
    final surfaceAlt = dark ? AppColors.darkSurfaceAlt : AppColors.surfaceAlt;
    final border = dark ? AppColors.darkBorder : AppColors.border;
    final onSurface = dark ? AppColors.darkText : AppColors.textDark;
    final muted = dark ? AppColors.darkMuted : AppColors.textMuted;
    final primary = dark ? const Color(0xFF2DD4B4) : AppColors.primary;
    final onPrimary = dark ? const Color(0xFF00211B) : Colors.white;

    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: brightness,
    ).copyWith(
      primary: primary,
      onPrimary: onPrimary,
      primaryContainer: dark ? const Color(0xFF0B4A3F) : AppColors.accent,
      onPrimaryContainer: dark ? const Color(0xFFB8F3DC) : AppColors.primaryDark,
      secondary: AppColors.secondary,
      onSecondary: Colors.white,
      surface: surface,
      onSurface: onSurface,
      onSurfaceVariant: muted,
      surfaceContainerLowest: bg,
      surfaceContainerLow: surface,
      surfaceContainer: surfaceAlt,
      surfaceContainerHigh: surfaceAlt,
      surfaceContainerHighest: surfaceAlt,
      outline: border,
      outlineVariant: border,
      error: dark ? const Color(0xFFF87171) : AppColors.statusDisqualified,
    );

    final baseText = ThemeData(brightness: brightness).textTheme;
    // Only the TextStyle (fontFamily) crosses the google_fonts boundary, which
    // keeps this independent of which Material library google_fonts targets.
    final bodyFamily = GoogleFonts.inter().fontFamily;
    final body = baseText.apply(fontFamily: bodyFamily);
    TextStyle h(TextStyle? s, double size, FontWeight w, {double ls = -0.2}) =>
        TextStyle(
          fontFamily: GoogleFonts.plusJakartaSans(fontWeight: w).fontFamily,
          fontSize: size,
          fontWeight: w,
          letterSpacing: ls,
          color: onSurface,
          height: 1.2,
        );

    final textTheme = body
        .copyWith(
          displayLarge: h(null, 44, FontWeight.w800, ls: -1),
          displayMedium: h(null, 36, FontWeight.w800, ls: -0.8),
          displaySmall: h(null, 30, FontWeight.w800, ls: -0.6),
          headlineLarge: h(null, 28, FontWeight.w700),
          headlineMedium: h(null, 24, FontWeight.w700),
          headlineSmall: h(null, 20, FontWeight.w700),
          titleLarge: h(null, 20, FontWeight.w700),
          titleMedium: h(null, 16, FontWeight.w700, ls: 0),
          titleSmall: h(null, 14, FontWeight.w600, ls: 0),
        )
        .apply(bodyColor: onSurface, displayColor: onSurface);

    final shape14 = RoundedRectangleBorder(borderRadius: Radii.mdAll);
    OutlineInputBorder inputBorder(Color c, [double w = 1]) =>
        OutlineInputBorder(
          borderRadius: Radii.mdAll,
          borderSide: BorderSide(color: c, width: w),
        );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: bg,
      textTheme: textTheme,
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      extensions: [dark ? StatusColors.dark : StatusColors.light],
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        foregroundColor: onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: Radii.lgAll,
          side: BorderSide(color: border),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: primary,
        textColor: onSurface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: Gap.lg, vertical: Gap.sm),
      ),
      dividerTheme: DividerThemeData(color: border, space: 1, thickness: 1),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: dark ? surfaceAlt : surface,
        hintStyle: TextStyle(color: muted),
        labelStyle: TextStyle(color: muted),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: Gap.lg, vertical: Gap.lg),
        border: inputBorder(border),
        enabledBorder: inputBorder(border),
        focusedBorder: inputBorder(primary, 1.8),
        errorBorder: inputBorder(scheme.error),
        focusedErrorBorder: inputBorder(scheme.error, 1.8),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          minimumSize: const Size(48, 52),
          shape: shape14,
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          elevation: 0,
          minimumSize: const Size(48, 52),
          shape: shape14,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: BorderSide(color: border),
          minimumSize: const Size(48, 52),
          shape: shape14,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          shape: shape14,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceAlt,
        selectedColor: scheme.primaryContainer,
        side: BorderSide(color: border),
        shape: const StadiumBorder(),
        labelStyle: TextStyle(color: onSurface, fontWeight: FontWeight.w600),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: onPrimary,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: Radii.lgAll),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: scheme.primaryContainer,
        elevation: 0,
        height: 68,
        labelTextStyle: WidgetStateProperty.resolveWith((s) => TextStyle(
              fontSize: 12,
              fontWeight:
                  s.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
              color: s.contains(WidgetState.selected) ? primary : muted,
            )),
        iconTheme: WidgetStateProperty.resolveWith((s) => IconThemeData(
              color: s.contains(WidgetState.selected)
                  ? scheme.onPrimaryContainer
                  : muted,
            )),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: surface,
        indicatorColor: scheme.primaryContainer,
        selectedIconTheme: IconThemeData(color: scheme.onPrimaryContainer),
        unselectedIconTheme: IconThemeData(color: muted),
        selectedLabelTextStyle:
            TextStyle(color: primary, fontWeight: FontWeight.w700),
        unselectedLabelTextStyle: TextStyle(color: muted),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: primary,
        unselectedItemColor: muted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: shape14,
        backgroundColor: dark ? AppColors.darkSurfaceAlt : AppColors.textDark,
        contentTextStyle: const TextStyle(color: Colors.white),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(borderRadius: Radii.xlAll),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.xl)),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: primary),
    );
  }
}
