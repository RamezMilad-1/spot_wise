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
      child: Column(
        children: [
          _Header(user: user),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              children: [
                if (user != null) ...[
                  _tile(context, Icons.person_outline_rounded, 'Profile',
                      () => _go(context, AppRoutes.profile)),
                  _tile(context, Icons.place_outlined, 'Spots I posted',
                      () => _go(context, AppRoutes.mySpots)),
                  _tile(context, Icons.favorite_border_rounded, 'Saved spots',
                      () => _go(context, AppRoutes.favorites)),
                  if (user.isAdmin)
                    _tile(context, Icons.shield_outlined, 'Admin panel',
                        () => _go(context, AppRoutes.adminDashboard)),
                  const Divider(),
                ],
                _tile(context, Icons.settings_outlined, 'Settings',
                    () => _go(context, AppRoutes.settings)),
                _tile(context, Icons.extension_outlined, 'Integrations & setup',
                    () => _go(context, AppRoutes.integrations)),
                SwitchListTile(
                  secondary: Icon(
                    themeP.isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                    color: AppColors.teal,
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

  Widget _tile(BuildContext context, IconData icon, String label, VoidCallback onTap,
      {bool danger = false}) {
    return ListTile(
      leading: Icon(icon, color: danger ? AppColors.danger : AppColors.teal),
      title: Text(
        label,
        style: Theme.of(context)
            .textTheme
            .titleSmall
            ?.copyWith(color: danger ? AppColors.danger : null),
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
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(gradient: AppColors.lagoonGradient),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: user == null
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.travel_explore_rounded, color: Colors.white, size: 40),
                    const SizedBox(height: AppSpacing.md),
                    Text('Welcome to SpotWise',
                        style: text.titleLarge?.copyWith(color: Colors.white)),
                    const SizedBox(height: 4),
                    Text('Sign in to save spots, plan trips and post your own places.',
                        style: text.bodySmall?.copyWith(color: Colors.white70)),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    UserAvatar(photoUrl: user!.photoUrl, initials: user!.initials, radius: 28),
                    const SizedBox(height: AppSpacing.md),
                    Text(user!.name, style: text.titleLarge?.copyWith(color: Colors.white)),
                    Text(user!.email, style: text.bodySmall?.copyWith(color: Colors.white70)),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Icon(user!.role.icon, size: 14, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(user!.role.label,
                            style: text.labelMedium?.copyWith(color: Colors.white)),
                      ],
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
