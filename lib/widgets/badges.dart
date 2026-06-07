import 'package:flutter/material.dart';

import '../core/constants/categories.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../models/enums.dart';

/// Small rounded label with an icon, tinted by [color].
class Pill extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color color;
  final Color? background;
  final bool solid;

  const Pill({
    super.key,
    required this.label,
    this.icon,
    required this.color,
    this.background,
    this.solid = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = solid ? color : (background ?? color.withValues(alpha: 0.14));
    final fg = solid ? Colors.white : color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: AppRadius.brSm),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class CategoryChip extends StatelessWidget {
  final String categoryId;
  final bool solid;
  const CategoryChip(this.categoryId, {super.key, this.solid = false});

  @override
  Widget build(BuildContext context) {
    final c = Categories.byId(categoryId);
    return Pill(label: c.label, icon: c.icon, color: c.color, solid: solid);
  }
}

class PriceTag extends StatelessWidget {
  final PriceRange price;
  const PriceTag(this.price, {super.key});

  @override
  Widget build(BuildContext context) {
    return Pill(
      label: price.symbol,
      icon: price == PriceRange.free ? Icons.volunteer_activism_rounded : null,
      color: AppColors.success,
    );
  }
}

class StatusBadge extends StatelessWidget {
  final SpotStatus status;
  const StatusBadge(this.status, {super.key});

  @override
  Widget build(BuildContext context) =>
      Pill(label: status.label, icon: status.icon, color: status.color);
}

class VerifiedBadge extends StatelessWidget {
  const VerifiedBadge({super.key});
  @override
  Widget build(BuildContext context) =>
      const Pill(label: 'Verified', icon: Icons.verified_rounded, color: AppColors.info);
}

class HiddenGemBadge extends StatelessWidget {
  const HiddenGemBadge({super.key});
  @override
  Widget build(BuildContext context) => const Pill(
        label: 'Hidden gem',
        icon: Icons.auto_awesome_rounded,
        color: AppColors.coral,
      );
}

class TagChip extends StatelessWidget {
  final String label;
  const TagChip(this.label, {super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: AppRadius.brSm,
        border: Border.all(color: scheme.outline),
      ),
      child: Text(label, style: Theme.of(context).textTheme.bodySmall),
    );
  }
}
