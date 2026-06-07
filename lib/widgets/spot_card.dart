import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/utils/formatters.dart';
import '../models/spot.dart';
import 'badges.dart';
import 'network_photo.dart';
import 'rating_stars.dart';

/// The hero feed card — a photo-forward, Airbnb-style spot card.
class SpotCard extends StatelessWidget {
  final Spot spot;
  final VoidCallback? onTap;
  final bool isSaved;
  final VoidCallback? onToggleSave;
  final double? distanceMeters;

  const SpotCard({
    super.key,
    required this.spot,
    this.onTap,
    this.isSaved = false,
    this.onToggleSave,
    this.distanceMeters,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 10,
                  child: NetworkPhoto(spot.coverPhoto, width: double.infinity),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: const BoxDecoration(gradient: AppColors.photoScrim),
                  ),
                ),
                Positioned(
                  top: AppSpacing.md,
                  left: AppSpacing.md,
                  child: CategoryChip(spot.categoryId, solid: true),
                ),
                if (onToggleSave != null)
                  Positioned(top: AppSpacing.sm, right: AppSpacing.sm, child: _saveButton()),
                Positioned(
                  left: AppSpacing.md,
                  right: AppSpacing.md,
                  bottom: AppSpacing.md,
                  child: Row(
                    children: [
                      if (spot.hiddenGem) const HiddenGemBadge(),
                      if (spot.hiddenGem && spot.verified) const SizedBox(width: 6),
                      if (spot.verified) const VerifiedBadge(),
                    ],
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(spot.name,
                            style: text.titleLarge, maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      RatingStars(spot.rating, size: 15, showValue: true),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.place_outlined, size: 15, color: text.bodySmall?.color),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(spot.location,
                            style: text.bodyMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                      if (distanceMeters != null)
                        Text('· ${Formatters.distance(distanceMeters!)}', style: text.bodySmall),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      PriceTag(spot.priceRange),
                      const SizedBox(width: AppSpacing.sm),
                      if (spot.familyFriendly)
                        const Pill(
                          label: 'Family',
                          icon: Icons.family_restroom_rounded,
                          color: AppColors.teal,
                        ),
                      const Spacer(),
                      if (spot.reviewCount > 0)
                        Text('${Formatters.count(spot.reviewCount)} reviews', style: text.bodySmall),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _saveButton() {
    return Material(
      color: Colors.white.withValues(alpha: 0.92),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onToggleSave,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(
            isSaved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            color: AppColors.coral,
            size: 20,
          ),
        ),
      ),
    );
  }
}
