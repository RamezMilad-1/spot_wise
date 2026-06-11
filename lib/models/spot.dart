import 'package:latlong2/latlong.dart';

import '../core/utils/json_utils.dart';
import 'enums.dart';

/// A community-submitted place. Goes through the moderation queue
/// (`status`) before it appears on the public map/feed.
class Spot {
  final String id;
  final String name;
  final String description;
  final String country;
  final String city;
  final String categoryId;
  final double lat;
  final double lng;
  final List<String> photos;
  final double rating;
  final int reviewCount;
  final PriceRange priceRange;
  final bool isFree;
  final bool familyFriendly;
  final bool hiddenGem;
  final bool featured;
  final String bestTimeToVisit;
  final String locationNote;
  final List<String> tags;
  final SpotStatus status;
  final bool verified;
  final String submittedBy;
  final String submittedByName;
  final String? approvedBy;
  final String? rejectionReason;
  final int likeCount;
  final int saveCount;
  final DateTime createdAt;

  const Spot({
    required this.id,
    required this.name,
    required this.description,
    required this.country,
    required this.city,
    required this.categoryId,
    required this.lat,
    required this.lng,
    this.photos = const [],
    this.rating = 0,
    this.reviewCount = 0,
    this.priceRange = PriceRange.moderate,
    this.isFree = false,
    this.familyFriendly = false,
    this.hiddenGem = false,
    this.featured = false,
    this.bestTimeToVisit = '',
    this.locationNote = '',
    this.tags = const [],
    this.status = SpotStatus.pending,
    this.verified = false,
    required this.submittedBy,
    this.submittedByName = '',
    this.approvedBy,
    this.rejectionReason,
    this.likeCount = 0,
    this.saveCount = 0,
    required this.createdAt,
  });

  LatLng get latLng => LatLng(lat, lng);
  String? get coverPhoto => photos.isNotEmpty ? photos.first : null;
  String get location => [city, country].where((e) => e.isNotEmpty).join(', ');

  factory Spot.fromJson(String id, Map<dynamic, dynamic> json) {
    return Spot(
      id: id,
      name: JsonUtils.asString(json['name']),
      description: JsonUtils.asString(json['description']),
      country: JsonUtils.asString(json['country']),
      city: JsonUtils.asString(json['city']),
      categoryId: JsonUtils.asString(json['category'], 'sightseeing'),
      lat: JsonUtils.asDouble(json['lat']),
      lng: JsonUtils.asDouble(json['lng']),
      photos: JsonUtils.asStringList(json['photos']),
      rating: JsonUtils.asDouble(json['rating']),
      reviewCount: JsonUtils.asInt(json['reviewCount']),
      priceRange: PriceRange.fromString(
        JsonUtils.asStringOrNull(json['priceRange']),
      ),
      isFree: JsonUtils.asBool(json['isFree']),
      familyFriendly: JsonUtils.asBool(json['familyFriendly']),
      hiddenGem: JsonUtils.asBool(json['hiddenGem']),
      featured: JsonUtils.asBool(json['featured']),
      bestTimeToVisit: JsonUtils.asString(json['bestTimeToVisit']),
      locationNote: JsonUtils.asString(json['locationNote']),
      tags: JsonUtils.asStringList(json['tags']),
      status: SpotStatus.fromString(JsonUtils.asStringOrNull(json['status'])),
      verified: JsonUtils.asBool(json['verified']),
      submittedBy: JsonUtils.asString(json['submittedBy']),
      submittedByName: JsonUtils.asString(json['submittedByName']),
      approvedBy: JsonUtils.asStringOrNull(json['approvedBy']),
      rejectionReason: JsonUtils.asStringOrNull(json['rejectionReason']),
      likeCount: JsonUtils.asInt(json['likeCount']),
      saveCount: JsonUtils.asInt(json['saveCount']),
      createdAt: JsonUtils.asDate(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'description': description,
    'country': country,
    'city': city,
    'category': categoryId,
    'lat': lat,
    'lng': lng,
    'photos': photos,
    'rating': rating,
    'reviewCount': reviewCount,
    'priceRange': priceRange.value,
    'isFree': isFree,
    'familyFriendly': familyFriendly,
    'hiddenGem': hiddenGem,
    'featured': featured,
    'bestTimeToVisit': bestTimeToVisit,
    'locationNote': locationNote,
    'tags': tags,
    'status': status.value,
    'verified': verified,
    'submittedBy': submittedBy,
    'submittedByName': submittedByName,
    'approvedBy': approvedBy,
    'rejectionReason': rejectionReason,
    'likeCount': likeCount,
    'saveCount': saveCount,
    'createdAt': createdAt.millisecondsSinceEpoch,
  };

  Spot copyWith({
    String? name,
    String? description,
    String? country,
    String? city,
    String? categoryId,
    double? lat,
    double? lng,
    List<String>? photos,
    double? rating,
    int? reviewCount,
    PriceRange? priceRange,
    bool? isFree,
    bool? familyFriendly,
    bool? hiddenGem,
    bool? featured,
    String? bestTimeToVisit,
    String? locationNote,
    List<String>? tags,
    SpotStatus? status,
    bool? verified,
    String? approvedBy,
    String? rejectionReason,
    int? likeCount,
    int? saveCount,
  }) {
    return Spot(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      country: country ?? this.country,
      city: city ?? this.city,
      categoryId: categoryId ?? this.categoryId,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      photos: photos ?? this.photos,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      priceRange: priceRange ?? this.priceRange,
      isFree: isFree ?? this.isFree,
      familyFriendly: familyFriendly ?? this.familyFriendly,
      hiddenGem: hiddenGem ?? this.hiddenGem,
      featured: featured ?? this.featured,
      bestTimeToVisit: bestTimeToVisit ?? this.bestTimeToVisit,
      locationNote: locationNote ?? this.locationNote,
      tags: tags ?? this.tags,
      status: status ?? this.status,
      verified: verified ?? this.verified,
      submittedBy: submittedBy,
      submittedByName: submittedByName,
      approvedBy: approvedBy ?? this.approvedBy,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      likeCount: likeCount ?? this.likeCount,
      saveCount: saveCount ?? this.saveCount,
      createdAt: createdAt,
    );
  }
}
