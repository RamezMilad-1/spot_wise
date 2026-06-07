import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

enum AppButtonVariant { primary, accent, outline }

/// App-wide button with built-in loading state and an optional leading icon.
/// `primary` = teal (FilledButton), `accent` = coral (ElevatedButton),
/// `outline` = bordered.
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;
  final AppButtonVariant variant;
  final bool expand;

  const AppButton(
    this.label, {
    super.key,
    this.onPressed,
    this.loading = false,
    this.icon,
    this.variant = AppButtonVariant.primary,
    this.expand = true,
  });

  const AppButton.accent(
    this.label, {
    super.key,
    this.onPressed,
    this.loading = false,
    this.icon,
    this.expand = true,
  }) : variant = AppButtonVariant.accent;

  const AppButton.outline(
    this.label, {
    super.key,
    this.onPressed,
    this.loading = false,
    this.icon,
    this.expand = true,
  }) : variant = AppButtonVariant.outline;

  @override
  Widget build(BuildContext context) {
    final spinnerColor = variant == AppButtonVariant.outline ? AppColors.teal : Colors.white;
    final child = loading
        ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(strokeWidth: 2.4, color: spinnerColor),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: 8)],
              Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
            ],
          );

    final handler = loading ? null : onPressed;
    final Widget button = switch (variant) {
      AppButtonVariant.primary => FilledButton(onPressed: handler, child: child),
      AppButtonVariant.accent => ElevatedButton(onPressed: handler, child: child),
      AppButtonVariant.outline => OutlinedButton(onPressed: handler, child: child),
    };

    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}
