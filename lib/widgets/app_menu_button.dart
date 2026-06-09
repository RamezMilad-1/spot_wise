import 'package:flutter/material.dart';

/// Key for the [HomeShell]'s Scaffold, so the tab screens (which each have their
/// own Scaffold/AppBar nested in the shell body) can open the shared side drawer.
final GlobalKey<ScaffoldState> shellScaffoldKey = GlobalKey<ScaffoldState>();

/// Hamburger button placed as the `leading` of each tab screen's AppBar.
/// Opens the shell's [AppDrawer].
class AppMenuButton extends StatelessWidget {
  const AppMenuButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.menu_rounded),
      tooltip: 'Menu',
      onPressed: () => shellScaffoldKey.currentState?.openDrawer(),
    );
  }
}
