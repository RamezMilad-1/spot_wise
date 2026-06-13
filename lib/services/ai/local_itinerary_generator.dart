import 'package:latlong2/latlong.dart';

import '../../core/constants/categories.dart';
import '../../models/enums.dart';
import '../../models/itinerary.dart';
import '../../models/spot.dart';
import '../../models/trip.dart';
import 'trip_estimator.dart';

/// A surprisingly capable, fully on-device itinerary builder. It grounds the
/// plan on the app's approved spots, scores them against the traveller's
/// interests, budget tier and (optional) budget cap, spreads them across days,
/// then hands off to [TripEstimator] for accurate timing + a costed budget.
///
/// This powers the AI planner out of the box (no key required) and is the
/// safety net behind the real Gemini call.
class LocalItineraryGenerator {
  static const Distance _distance = Distance();

  Trip generate(AiPlanRequest req, List<Spot> spots, String userId) {
    final approved = spots
        .where((s) => s.status == SpotStatus.approved)
        .toList();
    final perDay = req.pace.stopsPerDay;
    final needed = req.dayCount * perDay;

    // Candidate pool: destination (city or within ~60km) first, then country,
    // then anything — so the plan is actually about the right place.
    final pool = <Spot>[];
    pool.addAll(
      approved.where((s) => _matchesCity(s, req.destination) || _near(s, req)),
    );
    if (pool.length < needed) {
      pool.addAll(
        approved.where(
          (s) => !pool.contains(s) && _matchesCountry(s, req.country),
        ),
      );
    }
    if (pool.isEmpty) pool.addAll(approved);

    final interests = req.interests.map((e) => e.toLowerCase()).toSet();
    final capped = req.budgetCap != null;
    pool.sort(
      (a, b) => _score(
        b,
        interests,
        req.budget,
        capped,
      ).compareTo(_score(a, interests, req.budget, capped)),
    );

    final chosen = pool.take(needed).toList();

    final rawDays = <TripDay>[];
    var idx = 0;
    for (var d = 0; d < req.dayCount && idx < chosen.length; d++) {
      final stops = <TripStop>[];
      for (var p = 0; p < perDay && idx < chosen.length; p++) {
        final s = chosen[idx++];
        stops.add(
          TripStop(
            spotId: s.id,
            name: s.name,
            photo: s.coverPhoto,
            categoryId: s.categoryId,
            lat: s.lat,
            lng: s.lng,
            note: noteFor(s),
            estimatedCost: TripEstimator.stopCost(s),
            durationMinutes: TripEstimator.durationMinutes(s.categoryId),
          ),
        );
      }
      if (stops.isEmpty) break;
      rawDays.add(
        TripDay(
          dayNumber: d + 1,
          date: req.startDate.add(Duration(days: d)),
          title: _dayTitle(stops, req.destination),
          stops: stops,
        ),
      );
    }

    // Accurate clock times + day-parts, then a costed budget.
    final scheduled = TripEstimator.schedule(rawDays);
    final days = [
      for (final day in scheduled)
        day.copyWith(summary: _daySummary(day.stops)),
    ];
    final cost = TripEstimator.total(days, pace: req.pace);

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
      estimatedCost: cost,
      budgetCap: req.budgetCap,
      notes:
          'Crafted by SpotWise AI around ${interests.isEmpty ? 'a balanced mix' : req.interests.join(', ')}'
          ' at a ${req.pace.label.toLowerCase()} pace.',
      createdAt: DateTime.now(),
    );
  }

  int _score(Spot s, Set<String> interests, PriceRange budget, bool capped) {
    var score = (s.rating * 10).round() + (s.reviewCount > 200 ? 6 : 0);
    final hay =
        '${s.tags.join(' ')} ${Categories.labelFor(s.categoryId)} ${s.description}'
            .toLowerCase();
    for (final i in interests) {
      if (hay.contains(i)) score += 25;
    }
    if (s.hiddenGem) score += 8;
    if (s.priceRange.index <= budget.index) score += 5;
    // When the traveller set a cap, nudge towards cheaper places.
    if (capped) score -= TripEstimator.stopCost(s).round();
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

  bool _near(Spot s, AiPlanRequest req) {
    if (req.lat == null || req.lng == null) return false;
    final km = _distance.as(
      LengthUnit.Kilometer,
      LatLng(req.lat!, req.lng!),
      s.latLng,
    );
    return km <= 60;
  }

  /// Short practical note for a stop (also the fallback when the AI returns
  /// none).
  String noteFor(Spot s) {
    if (s.bestTimeToVisit.isNotEmpty) {
      return 'Best around ${s.bestTimeToVisit.toLowerCase()}.';
    }
    if (s.tags.isNotEmpty) return s.tags.first;
    return Categories.labelFor(s.categoryId);
  }

  /// Tiny stop-word list so a free-text wish like "a spot with good arabic
  /// food" keys off "arabic"/"food" rather than the filler words.
  static const Set<String> _wishStopWords = {
    'the', 'and', 'for', 'with', 'good', 'great', 'best', 'nice', 'some',
    'that', 'this', 'have', 'has', 'want', 'need', 'like', 'spot', 'spots',
    'place', 'places', 'near', 'nearby', 'around', 'something', 'somewhere',
    'really', 'very', 'more', 'food',
  };

  /// Offline fallback for the AI stop swap: the best-rated candidate, with a
  /// nudge for staying close to the rejected stop and matching its category.
  ///
  /// When [prompt] is set it first keeps only candidates whose name/tags/
  /// category/description mention the wish's keywords; if none do, it returns
  /// null so the caller can tell the traveller nothing nearby matches.
  Spot? pickReplacement({
    required TripStop reject,
    required List<Spot> candidates,
    String prompt = '',
  }) {
    if (candidates.isEmpty) return null;

    var pool = candidates;
    final terms = prompt
        .toLowerCase()
        .split(RegExp(r'[^a-z0-9]+'))
        .where((w) => w.length > 2 && !_wishStopWords.contains(w))
        .toSet();
    if (terms.isNotEmpty) {
      final matched = candidates.where((s) {
        final hay =
            '${s.name} ${s.tags.join(' ')} '
                    '${Categories.labelFor(s.categoryId)} ${s.description}'
                .toLowerCase();
        return terms.any(hay.contains);
      }).toList();
      if (matched.isEmpty) return null;
      pool = matched;
    }

    int score(Spot s) {
      var sc = (s.rating * 10).round();
      if (s.categoryId == reject.categoryId) sc += 8;
      final km = _distance.as(
        LengthUnit.Kilometer,
        LatLng(reject.lat, reject.lng),
        s.latLng,
      );
      sc -= km.round().clamp(0, 40);
      return sc;
    }

    final sorted = [...pool]..sort((a, b) => score(b).compareTo(score(a)));
    return sorted.first;
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
    return stops
        .map((s) => '${s.dayPart.label.toLowerCase()}: ${s.name}')
        .join(' · ');
  }
}
