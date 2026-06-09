import 'package:latlong2/latlong.dart';

import '../core/utils/json_utils.dart';
import 'enums.dart';

/// A single planned visit within a trip day.
class TripStop {
  final String spotId;
  final String name;
  final String? photo;
  final String categoryId;
  final double lat;
  final double lng;
  final DayPart dayPart;
  final String note;
  final String suggestedTime;

  /// Estimated per-person spend at this stop (USD), derived from the spot's
  /// price tier + category by the trip estimator.
  final double estimatedCost;

  /// Estimated visit length in minutes (drives scheduling + the timeline).
  final int durationMinutes;

  const TripStop({
    required this.spotId,
    required this.name,
    this.photo,
    this.categoryId = 'sightseeing',
    required this.lat,
    required this.lng,
    this.dayPart = DayPart.morning,
    this.note = '',
    this.suggestedTime = '',
    this.estimatedCost = 0,
    this.durationMinutes = 0,
  });

  LatLng get latLng => LatLng(lat, lng);

  factory TripStop.fromJson(Map<dynamic, dynamic> json) => TripStop(
        spotId: JsonUtils.asString(json['spotId']),
        name: JsonUtils.asString(json['name']),
        photo: JsonUtils.asStringOrNull(json['photo']),
        categoryId: JsonUtils.asString(json['category'], 'sightseeing'),
        lat: JsonUtils.asDouble(json['lat']),
        lng: JsonUtils.asDouble(json['lng']),
        dayPart: DayPart.fromString(JsonUtils.asStringOrNull(json['dayPart'])),
        note: JsonUtils.asString(json['note']),
        suggestedTime: JsonUtils.asString(json['suggestedTime']),
        estimatedCost: JsonUtils.asDouble(json['estimatedCost']),
        durationMinutes: JsonUtils.asInt(json['durationMinutes']),
      );

  Map<String, dynamic> toJson() => {
        'spotId': spotId,
        'name': name,
        'photo': photo,
        'category': categoryId,
        'lat': lat,
        'lng': lng,
        'dayPart': dayPart.value,
        'note': note,
        'suggestedTime': suggestedTime,
        'estimatedCost': estimatedCost,
        'durationMinutes': durationMinutes,
      };

  TripStop copyWith({
    DayPart? dayPart,
    String? note,
    String? suggestedTime,
    double? estimatedCost,
    int? durationMinutes,
  }) =>
      TripStop(
        spotId: spotId,
        name: name,
        photo: photo,
        categoryId: categoryId,
        lat: lat,
        lng: lng,
        dayPart: dayPart ?? this.dayPart,
        note: note ?? this.note,
        suggestedTime: suggestedTime ?? this.suggestedTime,
        estimatedCost: estimatedCost ?? this.estimatedCost,
        durationMinutes: durationMinutes ?? this.durationMinutes,
      );
}

/// One day of a trip, holding an ordered list of stops.
class TripDay {
  final int dayNumber;
  final DateTime? date;
  final String title;
  final String summary;
  final List<TripStop> stops;

  const TripDay({
    required this.dayNumber,
    this.date,
    this.title = '',
    this.summary = '',
    this.stops = const [],
  });

  factory TripDay.fromJson(Map<dynamic, dynamic> json) => TripDay(
        dayNumber: JsonUtils.asInt(json['dayNumber'], 1),
        date: json['date'] == null ? null : JsonUtils.asDate(json['date']),
        title: JsonUtils.asString(json['title']),
        summary: JsonUtils.asString(json['summary']),
        stops: JsonUtils.asMapList(json['stops']).map(TripStop.fromJson).toList(),
      );

  Map<String, dynamic> toJson() => {
        'dayNumber': dayNumber,
        'date': date?.millisecondsSinceEpoch,
        'title': title,
        'summary': summary,
        'stops': stops.map((e) => e.toJson()).toList(),
      };

  TripDay copyWith({String? title, String? summary, List<TripStop>? stops}) =>
      TripDay(
        dayNumber: dayNumber,
        date: date,
        title: title ?? this.title,
        summary: summary ?? this.summary,
        stops: stops ?? this.stops,
      );
}

/// A saved trip: a destination, date range and a day-by-day plan. Trips are
/// kept offline in Hive and (when configured) synced to the backend.
class Trip {
  final String id;
  final String userId;
  final String destination;
  final String country;
  final double? lat;
  final double? lng;
  final DateTime startDate;
  final DateTime endDate;
  final List<TripDay> days;
  final String notes;
  final bool aiGenerated;
  final bool completed;
  final String? coverPhoto;
  final DateTime createdAt;

  /// Estimated total trip cost (USD): stop spend + daily meals & transport.
  final double estimatedCost;

  /// Optional max budget the traveller set (USD). Null = no cap.
  final double? budgetCap;

  /// ISO-ish currency label for display (defaults to USD).
  final String currency;

  const Trip({
    required this.id,
    required this.userId,
    required this.destination,
    this.country = '',
    this.lat,
    this.lng,
    required this.startDate,
    required this.endDate,
    this.days = const [],
    this.notes = '',
    this.aiGenerated = false,
    this.completed = false,
    this.coverPhoto,
    required this.createdAt,
    this.estimatedCost = 0,
    this.budgetCap,
    this.currency = 'USD',
  });

  int get dayCount => days.isNotEmpty
      ? days.length
      : (endDate.difference(startDate).inDays + 1).clamp(1, 365);
  int get stopCount => days.fold(0, (sum, d) => sum + d.stops.length);
  LatLng? get latLng => (lat != null && lng != null) ? LatLng(lat!, lng!) : null;

  /// True when an estimate exists and exceeds the traveller's cap.
  bool get overBudget => budgetCap != null && estimatedCost > budgetCap!;

  factory Trip.fromJson(String id, Map<dynamic, dynamic> json) {
    return Trip(
      id: id,
      userId: JsonUtils.asString(json['userId']),
      destination: JsonUtils.asString(json['destination']),
      country: JsonUtils.asString(json['country']),
      lat: json['lat'] == null ? null : JsonUtils.asDouble(json['lat']),
      lng: json['lng'] == null ? null : JsonUtils.asDouble(json['lng']),
      startDate: JsonUtils.asDate(json['startDate']),
      endDate: JsonUtils.asDate(json['endDate']),
      days: JsonUtils.asMapList(json['days']).map(TripDay.fromJson).toList(),
      notes: JsonUtils.asString(json['notes']),
      aiGenerated: JsonUtils.asBool(json['aiGenerated']),
      completed: JsonUtils.asBool(json['completed']),
      coverPhoto: JsonUtils.asStringOrNull(json['coverPhoto']),
      createdAt: JsonUtils.asDate(json['createdAt']),
      estimatedCost: JsonUtils.asDouble(json['estimatedCost']),
      budgetCap: json['budgetCap'] == null ? null : JsonUtils.asDouble(json['budgetCap']),
      currency: JsonUtils.asString(json['currency'], 'USD'),
    );
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'destination': destination,
        'country': country,
        'lat': lat,
        'lng': lng,
        'startDate': startDate.millisecondsSinceEpoch,
        'endDate': endDate.millisecondsSinceEpoch,
        'days': days.map((e) => e.toJson()).toList(),
        'notes': notes,
        'aiGenerated': aiGenerated,
        'completed': completed,
        'coverPhoto': coverPhoto,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'estimatedCost': estimatedCost,
        'budgetCap': budgetCap,
        'currency': currency,
      };

  Trip copyWith({
    String? destination,
    String? country,
    DateTime? startDate,
    DateTime? endDate,
    List<TripDay>? days,
    String? notes,
    bool? completed,
    String? coverPhoto,
    double? estimatedCost,
    double? budgetCap,
    String? currency,
  }) {
    return Trip(
      id: id,
      userId: userId,
      destination: destination ?? this.destination,
      country: country ?? this.country,
      lat: lat,
      lng: lng,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      days: days ?? this.days,
      notes: notes ?? this.notes,
      aiGenerated: aiGenerated,
      completed: completed ?? this.completed,
      coverPhoto: coverPhoto ?? this.coverPhoto,
      createdAt: createdAt,
      estimatedCost: estimatedCost ?? this.estimatedCost,
      budgetCap: budgetCap ?? this.budgetCap,
      currency: currency ?? this.currency,
    );
  }
}
