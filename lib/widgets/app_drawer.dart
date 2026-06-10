import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/routes/app_routes.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../models/app_user.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import 'app_button.dart';
import 'user_avatar.dart';

/// The shell side drawer: profile, the user's own spots, admin (if admin),
/// settings and theme. Shows a sign-in call-to-action for guests.
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  void _go(BuildContext context, String route) {
    Navigator.pop(context); // close the drawer first
    Navigator.pushNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final themeP = context.watch<ThemeProvider>();
    final user = auth.user;

    return Drawer(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(
          right: Radius.circular(AppRadius.xl),
        ),
      ),
      child: Column(
        children: [
          _Header(user: user),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              children: [
                if (user != null) ...[
                  _tile(
                    context,
                    Icons.person_outline_rounded,
                    'Profile',
                    () => _go(context, AppRoutes.profile),
                  ),
                  _tile(
                    context,
                    Icons.place_outlined,
                    'Spots I posted',
                    () => _go(context, AppRoutes.mySpots),
                  ),
                  _tile(
                    context,
                    Icons.favorite_border_rounded,
                    'Saved spots',
                    () => _go(context, AppRoutes.favorites),
                  ),
                  if (user.isAdmin)
                    _tile(
                      context,
                      Icons.shield_outlined,
                      'Admin panel',
                      () => _go(context, AppRoutes.adminDashboard),
                    ),
                  const Divider(),
                ],
                _tile(
                  context,
                  Icons.settings_outlined,
                  'Settings',
                  () => _go(context, AppRoutes.settings),
                ),
                _tile(
                  context,
                  Icons.extension_outlined,
                  'Integrations & setup',
                  () => _go(context, AppRoutes.integrations),
                ),
                SwitchListTile(
                  secondary: Icon(
                    themeP.isDark
                        ? Icons.dark_mode_rounded
                        : Icons.light_mode_rounded,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  title: const Text('Dark mode'),
                  value: themeP.isDark,
                  onChanged: (_) => themeP.toggle(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (user != null)
            _tile(context, Icons.logout_rounded, 'Sign out', () {
              final a = context.read<AuthProvider>();
              Navigator.pop(context);
              a.signOut();
            }, danger: true)
          else
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: AppButton(
                'Sign in',
                icon: Icons.login_rounded,
                onPressed: () {
                  final nav = Navigator.of(context);
                  nav.pop(); // close the drawer
                  nav.pushNamed(AppRoutes.login); // straight to sign in
                },
              ),
            ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }

  Widget _tile(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap, {
    bool danger = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: danger
            ? AppColors.danger
            : Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      title: Text(
        label,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: danger ? AppColors.danger : null,
        ),
      ),
      onTap: onTap,
    );
  }
}

class _Header extends StatelessWidget {
  final AppUser? user;
  const _Header({this.user});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      color: scheme.surfaceContainerLow,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.xl,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: user == null
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerHighest,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.travel_explore_rounded,
                        color: scheme.onSurface,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text('Welcome to SpotWise', style: text.titleLarge),
                    const SizedBox(height: 4),
                    Text(
                      'Sign in to save spots, plan trips and post your own places.',
                      style: text.bodySmall,
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    UserAvatar(
                      photoUrl: user!.photoUrl,
                      initials: user!.initials,
                      radius: 28,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(user!.name, style: text.titleLarge),
                    Text(user!.email, style: text.bodySmall),
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerHighest,
                        borderRadius: const BorderRadius.all(
                          Radius.circular(AppRadius.pill),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            user!.role.icon,
                            size: 14,
                            color: scheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(user!.role.label, style: text.labelMedium),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
