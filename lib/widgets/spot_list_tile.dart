import 'package:flutter/material.dart';

import '../core/constants/categories.dart';
import '../core/theme/app_spacing.dart';
import '../models/spot.dart';
import 'network_photo.dart';
import 'rating_stars.dart';

/// Compact horizontal spot row — used in search results, trip pickers and
/// bottom sheets.
class SpotListTile extends StatelessWidget {
  final Spot spot;
  final VoidCallback? onTap;
  final Widget? trailing;
  final String? subtitleOverride;

  const SpotListTile({
    super.key,
    required this.spot,
    this.onTap,
    this.trailing,
    this.subtitleOverride,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.brMd,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            NetworkPhoto(spot.coverPhoto, width: 64, height: 64, radius: AppRadius.brMd),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(spot.name,
                      style: text.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Text(
                    subtitleOverride ?? '${Categories.labelFor(spot.categoryId)} · ${spot.location}',
                    style: text.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  RatingStars(spot.rating, size: 13, showValue: true, count: spot.reviewCount),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            trailing ?? Icon(Icons.chevron_right_rounded, color: text.bodySmall?.color),
          ],
        ),
      ),
    );
  }
}
