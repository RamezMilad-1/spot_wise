import '../../models/enums.dart';
import '../../models/spot.dart';
import '../../models/trip.dart';

/// Single source of truth for trip timing and money.
///
/// Spots only store a coarse price *tier* (Free/$/$$/$$$), so we map tier +
/// category → a realistic per-person USD amount, and category → a typical visit
/// length. From those we (a) compute an authoritative, clock-accurate schedule
/// and (b) roll up a transparent budget. Both the AI generators and the trip UI
/// go through here so numbers always agree.
class TripEstimator {
  TripEstimator._();

  static const String symbol = r'$';

  /// Minutes between consecutive stops (walking/transit + settling in).
  static const int _travelBuffer = 30;

  /// Typical visit length per category, in minutes.
  static int durationMinutes(String categoryId) => switch (categoryId) {
        'museum' => 120,
        'landmark' => 90,
        'historic' => 75,
        'art' => 90,
        'nature' => 90,
        'beach' => 120,
        'viewpoint' => 45,
        'food' => 75,
        'cafe' => 45,
        'nightlife' => 120,
        'shopping' => 60,
        'adventure' => 180,
        _ => 75,
      };

  /// Per-person spend (USD) for a single stop, from its price tier + category.
  /// "Free" attractions cost nothing, but a free-listed café/eatery still
  /// implies a small spend.
  static double stopCost(Spot spot) {
    if (spot.isFree || spot.priceRange == PriceRange.free) {
      return switch (spot.categoryId) {
        'food' => 8.0,
        'cafe' => 4.0,
        _ => 0.0,
      };
    }
    return switch (spot.priceRange) {
      PriceRange.free => 0.0,
      PriceRange.budget => 10.0,
      PriceRange.moderate => 25.0,
      PriceRange.premium => 55.0,
    };
  }

  /// Daily meals + local transport allowance (USD), scaled by pace.
  static double dailyExtras(TripPace pace) {
    final transport = switch (pace) {
      TripPace.relaxed => 10.0,
      TripPace.balanced => 15.0,
      TripPace.packed => 22.0,
    };
    const meals = 18.0;
    return transport + meals;
  }

  /// Re-stamps every stop with an accurate clock time + day-part, starting at
  /// 09:00, advancing by each stop's duration + a travel buffer, and slotting a
  /// one-hour lunch break around midday. Preserves cost/duration on each stop.
  static List<TripDay> schedule(List<TripDay> days) =>
      [for (final day in days) day.copyWith(stops: _scheduleDay(day.stops))];

  static List<TripStop> _scheduleDay(List<TripStop> stops) {
    var clock = 9 * 60; // 09:00, in minutes since midnight
    var lunchInserted = false;
    final out = <TripStop>[];
    for (final stop in stops) {
      final dur = stop.durationMinutes > 0
          ? stop.durationMinutes
          : durationMinutes(stop.categoryId);
      // Break for lunch once we pass ~12:30, unless this stop is itself a meal.
      if (!lunchInserted &&
          clock >= 12 * 60 + 30 &&
          stop.categoryId != 'food' &&
          stop.categoryId != 'cafe') {
        clock += 60;
        lunchInserted = true;
      }
      final part = clock < 12 * 60
          ? DayPart.morning
          : (clock < 17 * 60 ? DayPart.afternoon : DayPart.evening);
      out.add(stop.copyWith(suggestedTime: _hhmm(clock), dayPart: part));
      clock += dur + _travelBuffer;
    }
    return out;
  }

  static String _hhmm(int minutes) {
    final h = (minutes ~/ 60) % 24;
    final m = minutes % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  /// Sum of every stop's estimated spend.
  static double stopsCost(List<TripDay> days) =>
      days.expand((d) => d.stops).fold(0.0, (s, st) => s + st.estimatedCost);

  /// Total meals + transport across all days.
  static double extrasCost(List<TripDay> days, TripPace pace) =>
      days.length * dailyExtras(pace);

  /// Full estimated trip cost: stop spend + daily extras.
  static double total(List<TripDay> days, {TripPace pace = TripPace.balanced}) =>
      stopsCost(days) + extrasCost(days, pace);
}
