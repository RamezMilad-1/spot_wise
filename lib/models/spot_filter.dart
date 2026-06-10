import 'package:latlong2/latlong.dart';

import 'enums.dart';
import 'spot.dart';

/// Discovery filters shared by the map, search and feed. Immutable — use
/// [copyWith] to derive a new filter.
class SpotFilter {
  final String query;
  final Set<String> categoryIds;
  final double minRating;
  final Set<PriceRange> priceRanges;
  final bool familyOnly;
  final bool freeOnly;
  final bool hiddenGemOnly;
  final double? maxDistanceKm;

  const SpotFilter({
    this.query = '',
    this.categoryIds = const {},
    this.minRating = 0,
    this.priceRanges = const {},
    this.familyOnly = false,
    this.freeOnly = false,
    this.hiddenGemOnly = false,
    this.maxDistanceKm,
  });

  bool get isActive =>
      query.isNotEmpty ||
      categoryIds.isNotEmpty ||
      minRating > 0 ||
      priceRanges.isNotEmpty ||
      familyOnly ||
      freeOnly ||
      hiddenGemOnly ||
      maxDistanceKm != null;

  int get activeCount => [
    categoryIds.isNotEmpty,
    minRating > 0,
    priceRanges.isNotEmpty,
    familyOnly,
    freeOnly,
    hiddenGemOnly,
    maxDistanceKm != null,
  ].where((e) => e).length;

  static const Distance _distance = Distance();

  bool matches(Spot spot, {LatLng? origin}) {
    if (query.isNotEmpty) {
      final q = query.toLowerCase();
      final hay =
          '${spot.name} ${spot.city} ${spot.country} ${spot.tags.join(' ')}'
              .toLowerCase();
      if (!hay.contains(q)) return false;
    }
    if (categoryIds.isNotEmpty && !categoryIds.contains(spot.categoryId)) {
      return false;
    }
    if (spot.rating < minRating) return false;
    if (priceRanges.isNotEmpty && !priceRanges.contains(spot.priceRange)) {
      return false;
    }
    if (familyOnly && !spot.familyFriendly) return false;
    if (freeOnly && !spot.isFree) return false;
    if (hiddenGemOnly && !spot.hiddenGem) return false;
    if (maxDistanceKm != null && origin != null) {
      final km = _distance.as(LengthUnit.Kilometer, origin, spot.latLng);
      if (km > maxDistanceKm!) return false;
    }
    return true;
  }

  SpotFilter copyWith({
    String? query,
    Set<String>? categoryIds,
    double? minRating,
    Set<PriceRange>? priceRanges,
    bool? familyOnly,
    bool? freeOnly,
    bool? hiddenGemOnly,
    double? maxDistanceKm,
    bool clearDistance = false,
  }) {
    return SpotFilter(
      query: query ?? this.query,
      categoryIds: categoryIds ?? this.categoryIds,
      minRating: minRating ?? this.minRating,
      priceRanges: priceRanges ?? this.priceRanges,
      familyOnly: familyOnly ?? this.familyOnly,
      freeOnly: freeOnly ?? this.freeOnly,
      hiddenGemOnly: hiddenGemOnly ?? this.hiddenGemOnly,
      maxDistanceKm: clearDistance
          ? null
          : (maxDistanceKm ?? this.maxDistanceKm),
    );
  }
}
