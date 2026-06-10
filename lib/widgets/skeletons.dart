import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../core/theme/app_spacing.dart';

/// A single shimmering placeholder block.
class ShimmerBox extends StatelessWidget {
  final double? width;
  final double? height;
  final BorderRadius? radius;

  const ShimmerBox({super.key, this.width, this.height, this.radius});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Shimmer.fromColors(
      baseColor: scheme.surfaceContainerHighest,
      highlightColor: scheme.surface,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: radius ?? AppRadius.brSm,
        ),
      ),
    );
  }
}

/// Skeleton that mirrors a [SpotCard] while the feed loads.
class SpotCardSkeleton extends StatelessWidget {
  const SpotCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShimmerBox(height: 210, radius: AppRadius.brCard),
        const SizedBox(height: AppSpacing.md),
        const ShimmerBox(height: 16, width: 180),
        const SizedBox(height: AppSpacing.sm),
        const ShimmerBox(height: 12, width: 120),
      ],
    );
  }
}

/// A scrollable list of feed skeletons.
class SpotFeedSkeleton extends StatelessWidget {
  final int count;
  const SpotFeedSkeleton({super.key, this.count = 4});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: AppSpacing.screenPadding.copyWith(
        top: AppSpacing.lg,
        bottom: MediaQuery.paddingOf(context).bottom + AppSpacing.lg,
      ),
      itemCount: count,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.xl),
      itemBuilder: (_, _) => const SpotCardSkeleton(),
    );
  }
}
