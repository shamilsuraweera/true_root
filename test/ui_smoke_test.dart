import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:true_root/core/theme/app_theme.dart';
import 'package:true_root/core/widgets/adaptive_shell.dart';
import 'package:true_root/core/widgets/app_widgets.dart';
import 'package:true_root/core/widgets/brand_logo.dart';
import 'package:true_root/features/auth/login_page.dart';
import 'package:true_root/features/auth/register_page.dart';

Widget _app(Widget child, {ThemeMode mode = ThemeMode.light}) => ProviderScope(
      child: MaterialApp(
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: mode,
        home: child,
      ),
    );

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  const sizes = [Size(390, 844), Size(820, 1180), Size(1440, 900)];

  for (final size in sizes) {
    for (final mode in [ThemeMode.light, ThemeMode.dark]) {
      final tag = '${size.width.toInt()}x${size.height.toInt()} ${mode.name}';

      testWidgets('login renders without overflow @ $tag', (t) async {
        t.view.physicalSize = size;
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.reset);
        await t.pumpWidget(_app(const LoginPage(), mode: mode));
        await t.pump(const Duration(seconds: 1));
        expect(find.text('Sign in'), findsOneWidget);
      });

      testWidgets('register renders @ $tag', (t) async {
        t.view.physicalSize = size;
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.reset);
        await t.pumpWidget(_app(const RegisterPage(), mode: mode));
        await t.pump(const Duration(seconds: 1));
        expect(find.text('Create account'), findsOneWidget);
      });

      testWidgets('shell + components @ $tag', (t) async {
        t.view.physicalSize = size;
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.reset);
        await t.pumpWidget(_app(
          AdaptiveShell(
            destinations: const [
              ShellDestination(
                  label: 'A', icon: Icons.home_outlined, selectedIcon: Icons.home),
              ShellDestination(
                  label: 'B', icon: Icons.person_outline, selectedIcon: Icons.person),
            ],
            selectedIndex: 0,
            onSelected: (_) {},
            body: ListView(children: const [
              KpiCard(label: 'Batches', value: '12', icon: Icons.inventory_2),
              StatusPill('ACTIVE'),
              LoadingList(),
              EmptyState(title: 'Nothing here'),
              BrandLogo(showWordmark: true),
            ]),
          ),
          mode: mode,
        ));
        await t.pump(const Duration(seconds: 1));
        expect(find.text('Batches'), findsOneWidget);
      });
    }
  }
}
