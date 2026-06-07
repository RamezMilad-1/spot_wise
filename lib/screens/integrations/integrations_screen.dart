import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

enum _Status { active, connected, mock, deferred }

class _Integration {
  final IconData icon;
  final String title;
  final String description;
  final _Status status;
  final String? envKey;
  const _Integration(this.icon, this.title, this.description, this.status, [this.envKey]);
}

/// The "set it up later" hub. Shows every integration with live status and the
/// exact `.env` key needed to switch it on. The app runs fully without any of
/// these — they're documented here so connecting them later is a 5-minute job.
class IntegrationsScreen extends StatelessWidget {
  const IntegrationsScreen({super.key});

  List<_Integration> _items() => [
        const _Integration(Icons.map_rounded, 'Maps — OpenStreetMap',
            'Interactive map tiles. Free, no key, working now.', _Status.active),
        const _Integration(Icons.travel_explore_rounded, 'City search — Nominatim',
            'Worldwide geocoding for the search bar. Free, no key, working now.', _Status.active),
        const _Integration(Icons.directions_rounded, 'Open in Google Maps',
            'Hands off to the Maps app for directions via a URL. No key needed.', _Status.active),
        _Integration(
          Icons.storage_rounded,
          'Database — Firebase Realtime DB',
          'Currently using on-device Hive with seeded data. Add a database URL to sync to the cloud (REST, already coded).',
          AppConfig.hasFirebaseDb ? _Status.connected : _Status.mock,
          'FIREBASE_DB_URL',
        ),
        _Integration(
          Icons.lock_outline_rounded,
          'Authentication — Firebase Auth',
          'Currently using local email/password with demo accounts. Add an API key to use Firebase Auth (REST, already coded).',
          AppConfig.hasFirebaseAuth ? _Status.connected : _Status.mock,
          'FIREBASE_API_KEY',
        ),
        _Integration(
          Icons.auto_awesome_rounded,
          'AI planner — Google Gemini',
          'Currently using the on-device itinerary generator. Add a Gemini key to call the real model (already coded).',
          AppConfig.hasGemini ? _Status.connected : _Status.mock,
          'GEMINI_API_KEY',
        ),
        const _Integration(Icons.cloud_upload_outlined, 'Photo storage — Firebase Storage',
            'Photos are kept on-device for now. Cloud upload needs the Firebase Blaze plan.', _Status.deferred),
        const _Integration(Icons.notifications_active_outlined, 'Push — Firebase Cloud Messaging',
            'On-device + in-app notifications work now. Cross-device push needs FCM setup.', _Status.deferred),
      ];

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Integrations & setup')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              gradient: AppColors.lagoonGradient,
              borderRadius: AppRadius.brLg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.bolt_rounded, color: Colors.white),
                    SizedBox(width: AppSpacing.sm),
                    Text('Runs with zero setup',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Everything you see works on local/free services. Add the keys below to a .env file '
                  'to connect the real cloud backends — the code is already wired.',
                  style: text.bodyMedium?.copyWith(color: Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          for (final item in _items()) _IntegrationCard(item: item),
        ],
      ),
    );
  }
}

class _IntegrationCard extends StatelessWidget {
  final _Integration item;
  const _IntegrationCard({required this.item});

  (Color, String) _statusStyle() => switch (item.status) {
        _Status.active => (AppColors.success, 'Active'),
        _Status.connected => (AppColors.success, 'Connected'),
        _Status.mock => (AppColors.warning, 'Local mock'),
        _Status.deferred => (AppColors.inkFaint, 'Set up later'),
      };

  @override
  Widget build(BuildContext context) {
    final (color, label) = _statusStyle();
    final text = Theme.of(context).textTheme;
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(item.icon, color: AppColors.teal),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: Text(item.title, style: text.titleSmall)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.16), borderRadius: AppRadius.brSm),
                  child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(item.description, style: text.bodyMedium),
            if (item.envKey != null) ...[
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: AppRadius.brSm,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.key_rounded, size: 16),
                    const SizedBox(width: AppSpacing.sm),
                    Text('${item.envKey}=…', style: text.bodySmall?.copyWith(fontFamily: 'monospace')),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
