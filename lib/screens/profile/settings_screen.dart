import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_config.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_spacing.dart';
import '../../providers/spots_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/trips_provider.dart';
import '../../services/service_locator.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/feedback.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _resetDemo(BuildContext context) async {
    final local = services.localBackend;
    if (local == null) return;
    final ok = await showConfirmSheet(
      context,
      title: 'Reset demo data?',
      message: 'This restores the original seeded spots, trips and notifications.',
      confirmLabel: 'Reset',
      icon: Icons.restart_alt_rounded,
    );
    if (!ok || !context.mounted) return;
    final spotsP = context.read<SpotsProvider>();
    final tripsP = context.read<TripsProvider>();
    final messenger = ScaffoldMessenger.of(context);
    await local.reseed();
    await spotsP.load(force: true);
    await tripsP.load();
    messenger.showSnackBar(const SnackBar(content: Text('Demo data restored.')));
  }

  @override
  Widget build(BuildContext context) {
    final themeP = context.watch<ThemeProvider>();
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text('Appearance', style: text.titleMedium),
          const SizedBox(height: AppSpacing.md),
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(value: ThemeMode.system, label: Text('System'), icon: Icon(Icons.brightness_auto_rounded)),
              ButtonSegment(value: ThemeMode.light, label: Text('Light'), icon: Icon(Icons.light_mode_rounded)),
              ButtonSegment(value: ThemeMode.dark, label: Text('Dark'), icon: Icon(Icons.dark_mode_rounded)),
            ],
            selected: {themeP.mode},
            onSelectionChanged: (s) => themeP.setMode(s.first),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Setup', style: text.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.extension_outlined),
            title: const Text('Integrations & setup'),
            subtitle: const Text('Connect Firebase, Gemini and more — later'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => Navigator.pushNamed(context, AppRoutes.integrations),
          ),
          if (services.localBackend != null)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.restart_alt_rounded),
              title: const Text('Reset demo data'),
              subtitle: const Text('Restore the original seeded content'),
              onTap: () => _resetDemo(context),
            ),
          const SizedBox(height: AppSpacing.xl),
          Center(
            child: Column(
              children: [
                const AppLogo(size: 40),
                const SizedBox(height: AppSpacing.md),
                Text(AppConfig.tagline, style: text.bodySmall),
                Text('Version ${AppConfig.version}', style: text.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
