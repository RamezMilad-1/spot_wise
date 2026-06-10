import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_spacing.dart';
import '../../providers/auth_provider.dart';
import '../../providers/trips_provider.dart';
import '../../widgets/badges.dart';
import '../../widgets/user_avatar.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final tripsCount = context.watch<TripsProvider>().trips.length;
    final savedCount = user?.savedSpotIds.length ?? 0;
    final text = Theme.of(context).textTheme;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.settings),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Row(
            children: [
              UserAvatar(
                photoUrl: user.photoUrl,
                initials: user.initials,
                radius: 48,
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.name, style: text.headlineSmall),
                    Text(user.email, style: text.bodySmall),
                    const SizedBox(height: AppSpacing.sm),
                    Pill(
                      label: user.role.label,
                      icon: user.role.icon,
                      color: Theme.of(context).colorScheme.onSurface,
                      background: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              _Stat(value: '$tripsCount', label: 'Trips'),
              _Stat(value: '$savedCount', label: 'Saved'),
              _Stat(value: '${user.interests.length}', label: 'Interests'),
            ],
          ),
          if (user.interests.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xl),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [for (final i in user.interests) TagChip(i)],
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          _Tile(
            icon: Icons.edit_outlined,
            label: 'Edit profile',
            onTap: () => Navigator.pushNamed(context, AppRoutes.editProfile),
          ),
          _Tile(
            icon: Icons.place_outlined,
            label: 'Spots I posted',
            onTap: () => Navigator.pushNamed(context, AppRoutes.mySpots),
          ),
          _Tile(
            icon: Icons.favorite_border_rounded,
            label: 'Saved spots',
            onTap: () => Navigator.pushNamed(context, AppRoutes.favorites),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;
  const _Stat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: AppRadius.brLg,
        ),
        child: Column(
          children: [
            Text(value, style: Theme.of(context).textTheme.headlineSmall),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _Tile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 20, color: scheme.onSurfaceVariant),
      ),
      title: Text(label, style: Theme.of(context).textTheme.titleSmall),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}
