import 'package:flutter/material.dart';

import '../core/constants/categories.dart';
import '../core/theme/app_colors.dart';

/// A circular, category-coloured map marker (Foursquare/Airbnb style). Grows
/// and gains a coral ring when selected.
class SpotMarker extends StatelessWidget {
  final String categoryId;
  final bool selected;
  final VoidCallback? onTap;

  const SpotMarker({
    super.key,
    required this.categoryId,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = Categories.byId(categoryId);
    final size = selected ? 46.0 : 38.0;
    return GestureDetector(
      onTap: onTap,
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: c.color,
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? AppColors.coral : Colors.white,
              width: selected ? 3 : 2.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(c.icon, color: Colors.white, size: selected ? 22 : 18),
        ),
      ),
    );
  }
}

/// Cluster bubble shown by the marker-cluster layer.
class ClusterMarker extends StatelessWidget {
  final int count;
  const ClusterMarker(this.count, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.teal,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        '$count',
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14),
      ),
    );
  }
}
