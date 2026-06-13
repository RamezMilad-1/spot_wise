import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import 'app_button.dart';

enum SnackType { info, success, error }

/// Themed snackbars with a leading status icon.
class AppSnackbar {
  AppSnackbar._();

  static void show(
    BuildContext context,
    String message, {
    SnackType type = SnackType.info,
  }) {
    final (icon, color) = switch (type) {
      SnackType.success => (Icons.check_circle_rounded, AppColors.success),
      SnackType.error => (Icons.error_rounded, AppColors.danger),
      SnackType.info => (Icons.info_rounded, AppColors.amber),
    };
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: Text(message)),
            ],
          ),
        ),
      );
  }

  static void success(BuildContext context, String message) =>
      show(context, message, type: SnackType.success);
  static void error(BuildContext context, String message) =>
      show(context, message, type: SnackType.error);
}

/// Asks for an optional free-text note to steer an AI stop swap. Resolves to
/// the entered text (which may be empty → "best nearby pick") when the user taps
/// the confirm button, or null if they cancel/dismiss.
Future<String?> showSwapNoteSheet(
  BuildContext context, {
  String title = 'Swap this spot',
  String hint = 'e.g. a spot with great Arabic food',
  String confirmLabel = 'Swap',
}) async {
  final controller = TextEditingController();
  final result = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) {
      final text = Theme.of(ctx).textTheme;
      return Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.lg,
              AppSpacing.xl,
              AppSpacing.xl,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.auto_awesome_rounded,
                      color: AppColors.teal,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(child: Text(title, style: text.titleLarge)),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Tell the AI what you\'d prefer — or leave it blank for the '
                  'best nearby pick.',
                  style: text.bodySmall,
                ),
                const SizedBox(height: AppSpacing.lg),
                TextField(
                  controller: controller,
                  autofocus: true,
                  textInputAction: TextInputAction.done,
                  minLines: 1,
                  maxLines: 3,
                  decoration: InputDecoration(hintText: hint),
                  onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
                ),
                const SizedBox(height: AppSpacing.lg),
                AppButton(
                  confirmLabel,
                  icon: Icons.autorenew_rounded,
                  onPressed: () => Navigator.pop(ctx, controller.text.trim()),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
  controller.dispose();
  return result;
}

/// A confirmation bottom sheet. Resolves to true if the user confirms.
Future<bool> showConfirmSheet(
  BuildContext context, {
  required String title,
  String? message,
  String confirmLabel = 'Confirm',
  IconData? icon,
  bool destructive = false,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    builder: (ctx) {
      final text = Theme.of(ctx).textTheme;
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.sm,
            AppSpacing.xl,
            AppSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (icon != null) ...[
                Center(
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: destructive
                          ? AppColors.coralMist
                          : Theme.of(ctx).colorScheme.surfaceContainerHighest,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      size: 30,
                      color: destructive
                          ? AppColors.danger
                          : Theme.of(ctx).colorScheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
              Text(title, style: text.titleLarge, textAlign: TextAlign.center),
              if (message != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  message,
                  style: text.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              destructive
                  ? AppButton.accent(
                      confirmLabel,
                      onPressed: () => Navigator.pop(ctx, true),
                    )
                  : AppButton(
                      confirmLabel,
                      onPressed: () => Navigator.pop(ctx, true),
                    ),
              const SizedBox(height: AppSpacing.sm),
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      );
    },
  );
  return result ?? false;
}
