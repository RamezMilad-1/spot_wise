import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Metadata for a spot category — drives marker icons, chips and filters.
class SpotCategory {
  final String id;
  final String label;
  final IconData icon;
  final Color color;

  const SpotCategory({
    required this.id,
    required this.label,
    required this.icon,
    required this.color,
  });
}

/// Canonical category catalog. Spots store a category *id*; everything visual
/// is looked up here so categories stay consistent across the app.
class Categories {
  Categories._();

  static const List<SpotCategory> all = [
    SpotCategory(id: 'landmark', label: 'Landmark', icon: Icons.account_balance_rounded, color: AppColors.teal),
    SpotCategory(id: 'museum', label: 'Museum', icon: Icons.museum_rounded, color: Color(0xFF6C5CE7)),
    SpotCategory(id: 'food', label: 'Food', icon: Icons.restaurant_rounded, color: AppColors.coral),
    SpotCategory(id: 'cafe', label: 'Café', icon: Icons.local_cafe_rounded, color: Color(0xFFB07A3E)),
    SpotCategory(id: 'nature', label: 'Nature', icon: Icons.park_rounded, color: Color(0xFF2E9E6B)),
    SpotCategory(id: 'beach', label: 'Beach', icon: Icons.beach_access_rounded, color: Color(0xFF1CA7C4)),
    SpotCategory(id: 'viewpoint', label: 'Viewpoint', icon: Icons.landscape_rounded, color: Color(0xFFE08A2C)),
    SpotCategory(id: 'nightlife', label: 'Nightlife', icon: Icons.nightlife_rounded, color: Color(0xFF9B59B6)),
    SpotCategory(id: 'shopping', label: 'Market', icon: Icons.storefront_rounded, color: Color(0xFFE84393)),
    SpotCategory(id: 'art', label: 'Art', icon: Icons.palette_rounded, color: Color(0xFFD63384)),
    SpotCategory(id: 'adventure', label: 'Adventure', icon: Icons.hiking_rounded, color: Color(0xFFE74C3C)),
    SpotCategory(id: 'historic', label: 'Historic', icon: Icons.castle_rounded, color: Color(0xFF8D6E63)),
  ];

  static SpotCategory byId(String id) =>
      all.firstWhere((c) => c.id == id, orElse: () => all.first);

  static IconData iconFor(String id) => byId(id).icon;
  static Color colorFor(String id) => byId(id).color;
  static String labelFor(String id) => byId(id).label;
}
