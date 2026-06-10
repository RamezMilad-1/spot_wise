import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// Visual style for [GlassIconButton].
enum GlassButtonStyle {
  /// Translucent white — for buttons sitting on top of photos.
  light,

  /// Translucent dark — for buttons on light/white surfaces (search, back).
  dark,
}

/// A circular, frosted-glass icon button — the reference travel app's
/// favorite / back / more / filter control. Purely presentational; wire any
/// behavior through [onTap].
class GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final String? tooltip;
  final double iconSize;
  final GlassButtonStyle style;
  final Color? iconColor;

  /// Real backdrop blur behind the button. Disable on surfaces where many
  /// buttons scroll at once and web FPS matters.
  final bool blur;

  const GlassIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.tooltip,
    this.iconSize = 20,
    this.style = GlassButtonStyle.light,
    this.iconColor,
    this.blur = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isLight = style == GlassButtonStyle.light;

    final Color bg;
    final Color fg;
    if (isLight) {
      bg = blur ? Colors.white.withValues(alpha: 0.65) : AppColors.glass;
      fg = iconColor ?? AppColors.ink;
    } else {
      bg = isDarkMode
          ? AppColors.glassDark
          : AppColors.ink.withValues(alpha: blur ? 0.45 : 0.5);
      fg = iconColor ?? Colors.white;
    }

    Widget button = Material(
      color: bg,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12), // 44px target with a 20px icon
          child: Icon(icon, size: iconSize, color: fg),
        ),
      ),
    );

    if (blur) {
      button = ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: button,
        ),
      );
    }

    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}
