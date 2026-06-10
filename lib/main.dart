import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'core/routes/app_routes.dart';
import 'providers/admin_provider.dart';
import 'providers/ai_planner_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/category_store.dart';
import 'providers/connectivity_provider.dart';
import 'providers/map_provider.dart';
import 'providers/notifications_provider.dart';
import 'providers/spots_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/trips_provider.dart';
import 'services/notifications/push_service.dart';
import 'services/service_locator.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // .env is optional — the app runs fully on local data without it.
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    /* no .env present — that's fine */
  }

  await Hive.initFlutter();
  await ServiceLocator.instance.init();

  // Push notifications (Android only; no-op elsewhere).
  await PushService.bootstrap();
  services.push.onOpen = (_) =>
      navigatorKey.currentState?.pushNamed(AppRoutes.notifications);
  await services.push.init();

  final theme = ThemeProvider();
  final categories = CategoryStore();
  final connectivity = ConnectivityProvider();
  await Future.wait([theme.load(), categories.load(), connectivity.init()]);

  final auth = AuthProvider()..bootstrap();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: theme),
        ChangeNotifierProvider.value(value: categories),
        ChangeNotifierProvider.value(value: connectivity),
        ChangeNotifierProvider.value(value: auth),
        ChangeNotifierProvider(create: (_) => SpotsProvider()),
        ChangeNotifierProvider(create: (_) => MapProvider()),
        ChangeNotifierProvider(create: (_) => TripsProvider()),
        ChangeNotifierProvider(create: (_) => AiPlannerProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
        ChangeNotifierProvider(create: (_) => NotificationsProvider()),
      ],
      child: const SpotWiseApp(),
    ),
  );
}
