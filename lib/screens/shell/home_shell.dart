import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/auth_gate.dart';
import '../../models/notification_item.dart';
import '../../providers/auth_provider.dart';
import '../../providers/spots_provider.dart';
import '../../providers/trips_provider.dart';
import '../../services/notifications/notification_stream.dart';
import '../../services/service_locator.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/app_menu_button.dart';
import '../ai/ai_planner_screen.dart';
import '../home/home_feed_screen.dart';
import '../map/map_screen.dart';
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

  Future<void> _addSpot() async {
    if (await ensureLoggedIn(context) && mounted) {
      if (mounted) Navigator.pushNamed(context, AppRoutes.addSpot);
    }
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
            key: shellScaffoldKey,
            drawer: const AppDrawer(),
            body: IndexedStack(index: tab.index, children: _screens),
            floatingActionButton: FloatingActionButton(
              onPressed: _addSpot,
              tooltip: 'Add a spot',
              elevation: 6,
              backgroundColor: AppColors.teal,
              shape: const CircleBorder(),
              child: Ink(
                decoration: const BoxDecoration(
                  gradient: AppColors.lagoonGradient,
                  shape: BoxShape.circle,
                ),
                child: Container(
                  width: 56,
                  height: 56,
                  alignment: Alignment.center,
                  child: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
                ),
              ),
            ),
            floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
            bottomNavigationBar: BottomAppBar(
              height: 64,
              padding: EdgeInsets.zero,
              shape: const CircularNotchedRectangle(),
              notchMargin: 8,
              child: Row(
                children: [
                  _NavItem(tab: tab, index: 0, icon: Icons.home_outlined, selectedIcon: Icons.home_rounded, label: 'Home'),
                  _NavItem(tab: tab, index: 1, icon: Icons.map_outlined, selectedIcon: Icons.map_rounded, label: 'Map'),
                  const SizedBox(width: 56),
                  _NavItem(tab: tab, index: 2, icon: Icons.auto_awesome_outlined, selectedIcon: Icons.auto_awesome_rounded, label: 'Plan'),
                  _NavItem(tab: tab, index: 3, icon: Icons.luggage_outlined, selectedIcon: Icons.luggage_rounded, label: 'Trips'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final HomeTab tab;
  final int index;
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  const _NavItem({
    required this.tab,
    required this.index,
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final selected = tab.index == index;
    final color = selected ? AppColors.teal : Theme.of(context).colorScheme.onSurfaceVariant;
    return Expanded(
      child: InkWell(
        onTap: () => tab.go(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(selected ? selectedIcon : icon, color: color, size: 24),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
