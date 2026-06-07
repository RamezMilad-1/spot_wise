import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/notification_item.dart';
import '../../providers/auth_provider.dart';
import '../../providers/spots_provider.dart';
import '../../providers/trips_provider.dart';
import '../../services/notifications/notification_stream.dart';
import '../../services/service_locator.dart';
import '../ai/ai_planner_screen.dart';
import '../home/home_feed_screen.dart';
import '../map/map_screen.dart';
import '../profile/profile_screen.dart';
import '../trips/trips_list_screen.dart';

/// Lets any tab jump to another tab (e.g. "Explore the map" from home).
class HomeTab extends ChangeNotifier {
  int index;
  HomeTab(this.index);
  void go(int i) {
    if (i == index) return;
    index = i;
    notifyListeners();
  }
}

class HomeShell extends StatefulWidget {
  final int initialIndex;
  const HomeShell({super.key, this.initialIndex = 0});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  late final HomeTab _tab = HomeTab(widget.initialIndex);

  static const _screens = [
    HomeFeedScreen(),
    MapScreen(),
    AiPlannerScreen(),
    TripsListScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SpotsProvider>().load();
      context.read<TripsProvider>().load();
      if (!kIsWeb) services.notifications.requestPermission();
    });
  }

  @override
  Widget build(BuildContext context) {
    final uid = context.select<AuthProvider, String?>((a) => a.user?.id);

    return ChangeNotifierProvider.value(
      value: _tab,
      child: StreamProvider<List<NotificationItem>>(
        create: (_) =>
            uid == null ? Stream.value(const <NotificationItem>[]) : watchNotifications(uid),
        initialData: const [],
        child: Consumer<HomeTab>(
          builder: (context, tab, _) => Scaffold(
            body: IndexedStack(index: tab.index, children: _screens),
            bottomNavigationBar: NavigationBar(
              selectedIndex: tab.index,
              onDestinationSelected: tab.go,
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home_rounded),
                  label: 'Home',
                ),
                NavigationDestination(
                  icon: Icon(Icons.map_outlined),
                  selectedIcon: Icon(Icons.map_rounded),
                  label: 'Map',
                ),
                NavigationDestination(
                  icon: Icon(Icons.auto_awesome_outlined),
                  selectedIcon: Icon(Icons.auto_awesome_rounded),
                  label: 'Plan',
                ),
                NavigationDestination(
                  icon: Icon(Icons.luggage_outlined),
                  selectedIcon: Icon(Icons.luggage_rounded),
                  label: 'Trips',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline_rounded),
                  selectedIcon: Icon(Icons.person_rounded),
                  label: 'Profile',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
