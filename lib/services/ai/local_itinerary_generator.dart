import '../../core/constants/categories.dart';
import '../../models/enums.dart';
import '../../models/itinerary.dart';
import '../../models/spot.dart';
import '../../models/trip.dart';

/// A surprisingly capable, fully on-device itinerary builder. It grounds the
/// plan on the app's approved spots, scores them against the traveller's
/// interests and budget, then spreads them across days and times of day.
///
/// This is what powers the AI planner out of the box (no key required) and the
/// safety net behind the real Gemini call.
class LocalItineraryGenerator {
  Trip generate(AiPlanRequest req, List<Spot> spots, String userId) {
    final approved = spots.where((s) => s.status == SpotStatus.approved).toList();
    final perDay = req.pace.stopsPerDay;
    final needed = req.dayCount * perDay;

    // Build the candidate pool: destination city first, then country, then all.
    final pool = <Spot>[];
    pool.addAll(approved.where((s) => _matchesCity(s, req.destination)));
    if (pool.length < needed) {
      pool.addAll(approved.where((s) =>
          !pool.contains(s) && _matchesCountry(s, req.country)));
    }
    if (pool.isEmpty) pool.addAll(approved);

    final interests = req.interests.map((e) => e.toLowerCase()).toSet();
    pool.sort((a, b) => _score(b, interests, req.budget).compareTo(_score(a, interests, req.budget)));

    final chosen = pool.take(needed).toList();
    const parts = [DayPart.morning, DayPart.afternoon, DayPart.evening];

    final days = <TripDay>[];
    var idx = 0;
    for (var d = 0; d < req.dayCount && idx < chosen.length; d++) {
      final stops = <TripStop>[];
      for (var p = 0; p < perDay && idx < chosen.length; p++) {
        final s = chosen[idx++];
        final part = parts[p % parts.length];
        stops.add(TripStop(
          spotId: s.id,
          name: s.name,
          photo: s.coverPhoto,
          categoryId: s.categoryId,
          lat: s.lat,
          lng: s.lng,
          dayPart: part,
          suggestedTime: _timeFor(part),
          note: _noteFor(s),
        ));
      }
      if (stops.isEmpty) break;
      days.add(TripDay(
        dayNumber: d + 1,
        date: req.startDate.add(Duration(days: d)),
        title: _dayTitle(stops, req.destination),
        summary: _daySummary(stops),
        stops: stops,
      ));
    }

    final endOffset = (days.length - 1).clamp(0, 365);
    return Trip(
      id: '',
      userId: userId,
      destination: req.destination,
      country: req.country,
      lat: req.lat,
      lng: req.lng,
      startDate: req.startDate,
      endDate: req.startDate.add(Duration(days: endOffset)),
      days: days,
      aiGenerated: true,
      coverPhoto: chosen.isNotEmpty ? chosen.first.coverPhoto : null,
      notes: 'Crafted by SpotWise AI around ${interests.isEmpty ? 'a balanced mix' : req.interests.join(', ')}'
          ' at a ${req.pace.label.toLowerCase()} pace.',
      createdAt: DateTime.now(),
    );
  }

  int _score(Spot s, Set<String> interests, PriceRange budget) {
    var score = (s.rating * 10).round() + (s.reviewCount > 200 ? 6 : 0);
    final hay = '${s.tags.join(' ')} ${Categories.labelFor(s.categoryId)} ${s.description}'.toLowerCase();
    for (final i in interests) {
      if (hay.contains(i)) score += 25;
    }
    if (s.hiddenGem) score += 8;
    if (s.priceRange.index <= budget.index) score += 5;
    return score;
  }

  bool _matchesCity(Spot s, String destination) {
    final d = destination.trim().toLowerCase();
    if (d.isEmpty) return false;
    return s.city.toLowerCase().contains(d) || d.contains(s.city.toLowerCase());
  }

  bool _matchesCountry(Spot s, String country) {
    final c = country.trim().toLowerCase();
    if (c.isEmpty) return false;
    return s.country.toLowerCase() == c;
  }

  String _timeFor(DayPart part) => switch (part) {
        DayPart.morning => '09:00',
        DayPart.afternoon => '14:00',
        DayPart.evening => '18:30',
      };

  String _noteFor(Spot s) {
    if (s.bestTimeToVisit.isNotEmpty) return 'Best around ${s.bestTimeToVisit.toLowerCase()}.';
    if (s.tags.isNotEmpty) return s.tags.first;
    return Categories.labelFor(s.categoryId);
  }

  String _dayTitle(List<TripStop> stops, String destination) {
    final labels = stops
        .map((s) => Categories.labelFor(s.categoryId))
        .toSet()
        .take(2)
        .toList();
    if (labels.isEmpty) return 'Exploring $destination';
    if (labels.length == 1) return '${labels.first} day';
    return '${labels[0]} & ${labels[1]}';
  }

  String _daySummary(List<TripStop> stops) {
    final parts = stops
        .map((s) => '${s.dayPart.label.toLowerCase()}: ${s.name}')
        .join(' · ');
    return parts;
  }
}
