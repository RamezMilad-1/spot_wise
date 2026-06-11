import 'package:latlong2/latlong.dart';

import 'enums.dart';
import 'spot.dart';

/// Discovery filters shared by the map, search and feed. Immutable — use
/// [copyWith] to derive a new filter.
class SpotFilter {
  final String query;

  /// Destination filter — empty string means "anywhere". [city] is only
  /// meaningful when [country] is set (the pickers enforce the cascade).
  final String country;
  final String city;

  final Set<String> categoryIds;
  final double minRating;
  final Set<PriceRange> priceRanges;
  final bool familyOnly;
  final bool freeOnly;
  final bool hiddenGemOnly;
  final double? maxDistanceKm;

  const SpotFilter({
    this.query = '',
    this.country = '',
    this.city = '',
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
      country.isNotEmpty ||
      city.isNotEmpty ||
      categoryIds.isNotEmpty ||
      minRating > 0 ||
      priceRanges.isNotEmpty ||
      familyOnly ||
      freeOnly ||
      hiddenGemOnly ||
      maxDistanceKm != null;

  /// Count of filters managed by the filter *sheet* (badge on the tune
  /// button). Destination (country/city) has its own picker, so it's excluded.
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

  static bool _sameName(String a, String b) =>
      a.trim().toLowerCase() == b.trim().toLowerCase();

  bool matches(Spot spot, {LatLng? origin}) {
    if (query.isNotEmpty) {
      final q = query.toLowerCase();
      final hay =
          '${spot.name} ${spot.city} ${spot.country} ${spot.tags.join(' ')}'
              .toLowerCase();
      if (!hay.contains(q)) return false;
    }
    // Case-insensitive: user-submitted spots may type "germany".
    if (country.isNotEmpty && !_sameName(spot.country, country)) return false;
    if (city.isNotEmpty && !_sameName(spot.city, city)) return false;
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
    String? country,
    String? city,
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
      country: country ?? this.country,
      city: city ?? this.city,
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
