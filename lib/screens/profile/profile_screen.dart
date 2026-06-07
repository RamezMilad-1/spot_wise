import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../providers/auth_provider.dart';
import '../../providers/trips_provider.dart';
import '../../widgets/badges.dart';
import '../../widgets/user_avatar.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _signOut(BuildContext context) async {
    await context.read<AuthProvider>().signOut();
    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (_) => false);
    }
  }

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
              UserAvatar(photoUrl: user.photoUrl, initials: user.initials, radius: 36),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.name, style: text.headlineSmall),
                    Text(user.email, style: text.bodySmall),
                    const SizedBox(height: AppSpacing.sm),
                    Pill(label: user.role.label, icon: user.role.icon, color: AppColors.teal),
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
            icon: Icons.favorite_border_rounded,
            label: 'Saved spots',
            onTap: () => Navigator.pushNamed(context, AppRoutes.favorites),
          ),
          if (user.canContribute)
            _Tile(
              icon: Icons.add_location_alt_outlined,
              label: 'Add a spot',
              onTap: () => Navigator.pushNamed(context, AppRoutes.addSpot),
            ),
          if (user.isAdmin)
            _Tile(
              icon: Icons.shield_outlined,
              label: 'Admin panel',
              onTap: () => Navigator.pushNamed(context, AppRoutes.adminDashboard),
            ),
          _Tile(
            icon: Icons.edit_outlined,
            label: 'Edit profile',
            onTap: () => Navigator.pushNamed(context, AppRoutes.editProfile),
          ),
          _Tile(
            icon: Icons.extension_outlined,
            label: 'Integrations & setup',
            onTap: () => Navigator.pushNamed(context, AppRoutes.integrations),
          ),
          _Tile(
            icon: Icons.chat_bubble_outline_rounded,
            label: 'Messages',
            trailing: const Text('Soon'),
            onTap: () => Navigator.pushNamed(context, AppRoutes.chat),
          ),
          const SizedBox(height: AppSpacing.sm),
          _Tile(
            icon: Icons.logout_rounded,
            label: 'Sign out',
            danger: true,
            onTap: () => _signOut(context),
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
          borderRadius: AppRadius.brMd,
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
  final bool danger;
  final Widget? trailing;

  const _Tile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppColors.danger : Theme.of(context).colorScheme.onSurface;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      leading: Icon(icon, color: danger ? AppColors.danger : AppColors.teal),
      title: Text(label, style: Theme.of(context).textTheme.titleSmall?.copyWith(color: color)),
      trailing: trailing ?? const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}
