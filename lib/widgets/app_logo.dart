import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// The SpotWise brand mark (a pin in a lagoon-gradient tile) with an optional
/// wordmark. Used on the splash, auth and onboarding screens.
class AppLogo extends StatelessWidget {
  final double size;
  final bool showWordmark;
  final bool stacked;
  final Color? wordmarkColor;

  const AppLogo({
    super.key,
    this.size = 44,
    this.showWordmark = true,
    this.stacked = false,
    this.wordmarkColor,
  });

  @override
  Widget build(BuildContext context) {
    final mark = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: AppColors.lagoonGradient,
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: [
          BoxShadow(
            color: AppColors.teal.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Icon(
        Icons.travel_explore_rounded,
        color: Colors.white,
        size: size * 0.6,
      ),
    );

    if (!showWordmark) return mark;

    final wordmark = Text(
      'SpotWise',
      style: TextStyle(
        fontSize: size * 0.62,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
        color: wordmarkColor ?? Theme.of(context).colorScheme.onSurface,
      ),
    );

    if (stacked) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          mark,
          SizedBox(height: size * 0.3),
          wordmark,
        ],
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        mark,
        SizedBox(width: size * 0.34),
        wordmark,
      ],
    );
  }
}
