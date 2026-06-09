import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../widgets/app_button.dart';
import '../routes/app_routes.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Gate an action behind authentication.
///
/// Returns `true` immediately if the user is already signed in. Otherwise it
/// shows a friendly "Sign in to continue" sheet, routes to login/register, and
/// resolves to whether the user is signed in afterwards — so the caller can
/// resume the action (save, post, generate, …) only once authenticated.
Future<bool> ensureLoggedIn(BuildContext context, {String? message}) async {
  final auth = context.read<AuthProvider>();
  if (auth.isLoggedIn) return true;

  // Capture the navigator up front so the flow still works even if [context]
  // is torn down while the sheet is open (e.g. when called from a Drawer item).
  final navigator = Navigator.of(context);

  final action = await showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (_) => _SignInPrompt(message: message),
  );
  if (action == null) return auth.isLoggedIn;

  final route = action == 'register' ? AppRoutes.register : AppRoutes.login;
  await navigator.pushNamed(route);
  return auth.isLoggedIn;
}

class _SignInPrompt extends StatelessWidget {
  final String? message;
  const _SignInPrompt({this.message});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                gradient: AppColors.lagoonGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock_open_rounded, color: Colors.white),
            ),
            const SizedBox(height: AppSpacing.md),
            Text('Sign in to continue', style: text.titleLarge, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.xs),
            Text(
              message ?? 'Create a free account to save spots, plan trips and post your own places.',
              style: text.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              'Sign in',
              icon: Icons.login_rounded,
              onPressed: () => Navigator.pop(context, 'login'),
            ),
            const SizedBox(height: AppSpacing.sm),
            AppButton.outline(
              'Create account',
              icon: Icons.person_add_alt_rounded,
              onPressed: () => Navigator.pop(context, 'register'),
            ),
          ],
        ),
      ),
    );
  }
}
