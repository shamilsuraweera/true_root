import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_routes.dart';
import 'core/theme/app_theme.dart';
import 'state/theme_state.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final defaultRoute = WidgetsBinding.instance.platformDispatcher.defaultRouteName;
    final fragment = Uri.base.fragment;
    final fragmentRoute = fragment.startsWith('/') ? fragment : '/$fragment';
    final hasFragmentRoute = fragment.isNotEmpty && fragmentRoute != '/';
    final initialRoute = hasFragmentRoute
        ? fragmentRoute
        : (defaultRoute != '/' && defaultRoute.isNotEmpty
            ? defaultRoute
            : AppRoutes.splash);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      initialRoute: initialRoute,
      routes: AppRoutes.routes,
    );
  }
}
