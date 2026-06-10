import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/utils/formatters.dart';
import '../models/spot.dart';
import 'badges.dart';
import 'glass_icon_button.dart';
import 'network_photo.dart';
import 'rating_stars.dart';

/// The vertical feed card — a big photo with a clean details strip below.
/// Used in the main "Explore" list. Public API unchanged.
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
                  aspectRatio: 4 / 3,
                  child: NetworkPhoto(spot.coverPhoto, width: double.infinity),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: const BoxDecoration(
                      gradient: AppColors.photoScrim,
                    ),
                  ),
                ),
                Positioned(
                  top: AppSpacing.md,
                  left: AppSpacing.md,
                  child: CategoryChip(spot.categoryId, glass: true),
                ),
                if (onToggleSave != null)
                  Positioned(
                    top: AppSpacing.sm,
                    right: AppSpacing.sm,
                    child: GlassIconButton(
                      icon: isSaved
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      iconColor: isSaved ? AppColors.coral : AppColors.ink,
                      onTap: onToggleSave,
                      tooltip: isSaved ? 'Saved' : 'Save',
                    ),
                  ),
                Positioned(
                  left: AppSpacing.md,
                  right: AppSpacing.md,
                  bottom: AppSpacing.md,
                  child: Row(
                    children: [
                      if (spot.hiddenGem) const HiddenGemBadge(),
                      if (spot.hiddenGem && spot.verified)
                        const SizedBox(width: 6),
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
                        child: Text(
                          spot.name,
                          style: text.titleLarge,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      RatingStars(spot.rating, size: 16, compact: true),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.place_outlined,
                        size: 15,
                        color: text.bodySmall?.color,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          spot.location,
                          style: text.bodyMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (distanceMeters != null)
                        Text(
                          '· ${Formatters.distance(distanceMeters!)}',
                          style: text.bodySmall,
                        ),
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
                        Text(
                          '${Formatters.count(spot.reviewCount)} reviews',
                          style: text.bodySmall,
                        ),
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
}

/// The editorial overlay card — a full-bleed photo with the name, location and
/// rating laid over a gradient. Used in the horizontal Featured / Recommended
/// rails. Same data + callbacks as [SpotCard].
class SpotOverlayCard extends StatelessWidget {
  final Spot spot;
  final VoidCallback? onTap;
  final bool isSaved;
  final VoidCallback? onToggleSave;

  const SpotOverlayCard({
    super.key,
    required this.spot,
    this.onTap,
    this.isSaved = false,
    this.onToggleSave,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            NetworkPhoto(spot.coverPhoto, fit: BoxFit.cover),
            const DecoratedBox(
              decoration: BoxDecoration(gradient: AppColors.cardScrim),
            ),
            Positioned(
              top: AppSpacing.md,
              left: AppSpacing.md,
              child: CategoryChip(spot.categoryId, glass: true),
            ),
            if (onToggleSave != null)
              Positioned(
                top: AppSpacing.sm,
                right: AppSpacing.sm,
                child: GlassIconButton(
                  icon: isSaved
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  iconColor: isSaved ? AppColors.coral : AppColors.ink,
                  onTap: onToggleSave,
                  tooltip: isSaved ? 'Saved' : 'Save',
                ),
              ),
            Positioned(
              left: AppSpacing.lg,
              right: AppSpacing.lg,
              bottom: AppSpacing.lg,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    spot.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.place, size: 14, color: Colors.white70),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          spot.location,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      RatingStars(
                        spot.rating,
                        size: 15,
                        compact: true,
                        valueColor: Colors.white,
                      ),
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
}
