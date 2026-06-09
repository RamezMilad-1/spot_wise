import 'enums.dart';

/// The user's brief for the AI planner — destination, dates and preferences.
/// Fed to the [AiService] which returns a day-by-day [Trip].
class AiPlanRequest {
  final String destination;
  final String country;
  final double? lat;
  final double? lng;
  final DateTime startDate;
  final int dayCount;
  final List<String> interests;
  final PriceRange budget;
  final TripPace pace;

  /// Optional max total budget (USD). Null = no cap.
  final double? budgetCap;

  const AiPlanRequest({
    required this.destination,
    this.country = '',
    this.lat,
    this.lng,
    required this.startDate,
    required this.dayCount,
    this.interests = const [],
    this.budget = PriceRange.moderate,
    this.pace = TripPace.balanced,
    this.budgetCap,
  });

  DateTime get endDate => startDate.add(Duration(days: dayCount - 1));

  AiPlanRequest copyWith({
    String? destination,
    String? country,
    double? lat,
    double? lng,
    DateTime? startDate,
    int? dayCount,
    List<String>? interests,
    PriceRange? budget,
    TripPace? pace,
    double? budgetCap,
  }) {
    return AiPlanRequest(
      destination: destination ?? this.destination,
      country: country ?? this.country,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      startDate: startDate ?? this.startDate,
      dayCount: dayCount ?? this.dayCount,
      interests: interests ?? this.interests,
      budget: budget ?? this.budget,
      pace: pace ?? this.pace,
      budgetCap: budgetCap ?? this.budgetCap,
    );
  }
}
