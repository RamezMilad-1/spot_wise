import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// Star rating display.
///
/// Default: five stars with an optional numeric value + review count.
/// [compact]: a single star + the value (e.g. `★ 4.8`) — for cards/overlays.
/// [valueColor] overrides the value text color (use white on photos).
class RatingStars extends StatelessWidget {
  final double rating;
  final double size;
  final bool showValue;
  final int? count;
  final Color? color;
  final bool compact;
  final Color? valueColor;

  const RatingStars(
    this.rating, {
    super.key,
    this.size = 16,
    this.showValue = false,
    this.count,
    this.color,
    this.compact = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final starColor = color ?? AppColors.amber;
    final valColor = valueColor ?? Theme.of(context).colorScheme.onSurface;

    if (compact) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, size: size, color: starColor),
          SizedBox(width: size * 0.22),
          Text(
            rating.toStringAsFixed(1),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: valColor,
            ),
          ),
          if (count != null) ...[
            SizedBox(width: size * 0.2),
            Text(
              '($count)',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: valColor),
            ),
          ],
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          Icon(
            rating >= i
                ? Icons.star_rounded
                : (rating >= i - 0.5
                      ? Icons.star_half_rounded
                      : Icons.star_outline_rounded),
            size: size,
            color: starColor,
          ),
        if (showValue) ...[
          SizedBox(width: size * 0.35),
          Text(
            rating.toStringAsFixed(1),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: valColor,
            ),
          ),
        ],
        if (count != null) ...[
          SizedBox(width: size * 0.25),
          Text('($count)', style: Theme.of(context).textTheme.bodySmall),
        ],
      ],
    );
  }
}
