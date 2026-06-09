import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/config/app_config.dart';
import 'core/routes/app_routes.dart';
import 'core/routes/router.dart';
import 'core/theme/app_theme.dart';
import 'providers/theme_provider.dart';

/// App-wide navigator key, so non-widget code (e.g. a notification tap handler)
/// can navigate.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class SpotWiseApp extends StatelessWidget {
  const SpotWiseApp({super.key});

  @override
  Widget build(BuildContext context) {
    final mode = context.watch<ThemeProvider>().mode;
    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: mode,
      initialRoute: AppRoutes.splash,
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}
