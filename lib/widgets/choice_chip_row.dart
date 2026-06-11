import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';

/// One selectable option in a [ChoiceChipRow].
class ChipOption<T> {
  final T value;
  final String label;
  final int? count;
  final IconData? icon;

  const ChipOption(this.value, this.label, {this.count, this.icon});
}

/// A single-select, horizontally scrollable row of chips with optional counts
/// — the "easy filter" building block used across the admin screens.
class ChoiceChipRow<T> extends StatelessWidget {
  final List<ChipOption<T>> options;
  final T selected;
  final ValueChanged<T> onSelected;
  final EdgeInsetsGeometry padding;

  const ChoiceChipRow({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
    this.padding = const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Mirrors the chip theme's ink fill so avatar icons flip with the label.
    final selectedIconColor = isDark ? AppColors.darkBg : Colors.white;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: padding,
      child: Row(
        children: [
          for (final (i, o) in options.indexed) ...[
            if (i > 0) const SizedBox(width: AppSpacing.sm),
            ChoiceChip(
              avatar: o.icon == null
                  ? null
                  : Icon(
                      o.icon,
                      size: 16,
                      color: o.value == selected
                          ? selectedIconColor
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              label: Text(o.count == null ? o.label : '${o.label} ${o.count}'),
              selected: o.value == selected,
              onSelected: (_) => onSelected(o.value),
            ),
          ],
        ],
      ),
    );
  }
}
