import 'dart:ui' show ImageFilter;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
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
      context.read<AuthProvider>().registerPushToken();
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
        create: (_) => uid == null
            ? Stream.value(const <NotificationItem>[])
            : watchNotifications(uid),
        initialData: const [],
        child: Consumer<HomeTab>(
          builder: (context, tab, _) => Scaffold(
            key: shellScaffoldKey,
            drawer: const AppDrawer(),
            extendBody: true,
            body: IndexedStack(index: tab.index, children: _screens),
            bottomNavigationBar: MediaQuery.viewInsetsOf(context).bottom > 0
                ? null
                : _FloatingDock(tab: tab, onAddSpot: _addSpot),
          ),
        ),
      ),
    );
  }
}

/// Frosted-glass pill dock floating above the bottom edge — the shell's
/// bottom navigation. Same four destinations + the center "Add a spot"
/// action; only the presentation changed.
class _FloatingDock extends StatelessWidget {
  final HomeTab tab;
  final VoidCallback onAddSpot;

  const _FloatingDock({required this.tab, required this.onAddSpot});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fill = isDark
        ? AppColors.darkSurface.withValues(alpha: 0.72)
        : Colors.white.withValues(alpha: 0.80);

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSpacing.dockMaxWidth),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.dock),
              boxShadow: AppColors.softShadow,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.dock),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  height: AppSpacing.dockHeight,
                  decoration: BoxDecoration(
                    color: fill,
                    borderRadius: BorderRadius.circular(AppRadius.dock),
                    border: Border.all(
                      color: scheme.outline.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      _NavItem(
                        tab: tab,
                        index: 0,
                        icon: Icons.home_outlined,
                        selectedIcon: Icons.home_rounded,
                        label: 'Home',
                      ),
                      _NavItem(
                        tab: tab,
                        index: 1,
                        icon: Icons.map_outlined,
                        selectedIcon: Icons.map_rounded,
                        label: 'Map',
                      ),
                      _DockAddButton(onTap: onAddSpot),
                      _NavItem(
                        tab: tab,
                        index: 2,
                        icon: Icons.auto_awesome_outlined,
                        selectedIcon: Icons.auto_awesome_rounded,
                        label: 'Plan',
                      ),
                      _NavItem(
                        tab: tab,
                        index: 3,
                        icon: Icons.luggage_outlined,
                        selectedIcon: Icons.luggage_rounded,
                        label: 'Trips',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Center "Add a spot" button — an ink circle inside the dock pill.
class _DockAddButton extends StatelessWidget {
  final VoidCallback onTap;

  const _DockAddButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      width: 64,
      child: Center(
        child: Tooltip(
          message: 'Add a spot',
          child: Material(
            color: isDark ? AppColors.darkInk : AppColors.ink,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              child: SizedBox(
                width: 52,
                height: 52,
                child: Icon(
                  Icons.add_rounded,
                  size: 26,
                  color: isDark ? AppColors.darkBg : Colors.white,
                ),
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
    final scheme = Theme.of(context).colorScheme;
    final color = selected ? scheme.onSurface : scheme.onSurfaceVariant;
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
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
