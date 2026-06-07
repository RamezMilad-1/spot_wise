import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// Five-star rating display with optional numeric value and review count.
class RatingStars extends StatelessWidget {
  final double rating;
  final double size;
  final bool showValue;
  final int? count;
  final Color? color;

  const RatingStars(
    this.rating, {
    super.key,
    this.size = 16,
    this.showValue = false,
    this.count,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final starColor = color ?? AppColors.amber;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          Icon(
            rating >= i
                ? Icons.star_rounded
                : (rating >= i - 0.5 ? Icons.star_half_rounded : Icons.star_outline_rounded),
            size: size,
            color: starColor,
          ),
        if (showValue) ...[
          SizedBox(width: size * 0.35),
          Text(
            rating.toStringAsFixed(1),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
          ),
        ],
        if (count != null) ...[
          SizedBox(width: size * 0.25),
          Text(
            '($count)',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ],
    );
  }
}
