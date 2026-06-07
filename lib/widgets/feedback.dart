import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import 'app_button.dart';

enum SnackType { info, success, error }

/// Themed snackbars with a leading status icon.
class AppSnackbar {
  AppSnackbar._();

  static void show(BuildContext context, String message, {SnackType type = SnackType.info}) {
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
          padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 40, color: destructive ? AppColors.danger : AppColors.teal),
                const SizedBox(height: AppSpacing.md),
              ],
              Text(title, style: text.titleLarge, textAlign: TextAlign.center),
              if (message != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(message, style: text.bodyMedium, textAlign: TextAlign.center),
              ],
              const SizedBox(height: AppSpacing.xl),
              destructive
                  ? AppButton.accent(confirmLabel, onPressed: () => Navigator.pop(ctx, true))
                  : AppButton(confirmLabel, onPressed: () => Navigator.pop(ctx, true)),
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
