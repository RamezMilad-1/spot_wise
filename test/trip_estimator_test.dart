import 'package:flutter_test/flutter_test.dart';
import 'package:spot_wise/models/enums.dart';
import 'package:spot_wise/models/itinerary.dart';
import 'package:spot_wise/models/spot.dart';
import 'package:spot_wise/models/trip.dart';
import 'package:spot_wise/services/ai/local_itinerary_generator.dart';
import 'package:spot_wise/services/ai/trip_estimator.dart';

Spot _spot(String id, String cat, PriceRange price, {bool free = false, String city = 'Cairo'}) => Spot(
      id: id,
      name: 'Spot $id',
      description: 'A nice place to visit in the city.',
      country: 'Egypt',
      city: city,
      categoryId: cat,
      lat: 30.0,
      lng: 31.0,
      priceRange: price,
      isFree: free,
      status: SpotStatus.approved,
      submittedBy: 'u1',
      createdAt: DateTime(2026, 1, 1),
    );

void main() {
  group('TripEstimator.stopCost', () {
    test('maps price tiers to USD amounts', () {
      expect(TripEstimator.stopCost(_spot('a', 'landmark', PriceRange.free)), 0);
      expect(TripEstimator.stopCost(_spot('b', 'landmark', PriceRange.budget)), 10);
      expect(TripEstimator.stopCost(_spot('c', 'museum', PriceRange.moderate)), 25);
      expect(TripEstimator.stopCost(_spot('d', 'nightlife', PriceRange.premium)), 55);
    });

    test('free-listed food/cafe still imply a small spend', () {
      expect(TripEstimator.stopCost(_spot('e', 'food', PriceRange.free, free: true)), 8);
      expect(TripEstimator.stopCost(_spot('f', 'cafe', PriceRange.free, free: true)), 4);
    });
  });

  group('TripEstimator.schedule', () {
    test('assigns realistic, increasing clock times from 09:00', () {
      final days = [
        TripDay(dayNumber: 1, stops: [
          const TripStop(spotId: 'a', name: 'A', lat: 0, lng: 0, categoryId: 'museum', durationMinutes: 120),
          const TripStop(spotId: 'b', name: 'B', lat: 0, lng: 0, categoryId: 'food', durationMinutes: 75),
        ]),
      ];
      final scheduled = TripEstimator.schedule(days);
      final stops = scheduled.first.stops;
      expect(stops.first.suggestedTime, '09:00');
      expect(stops.first.dayPart, DayPart.morning);
      // 09:00 + 120min visit + 30min travel = 11:30
      expect(stops[1].suggestedTime, '11:30');
    });

    test('adds traveller-requested rest between stops via gapMinutes', () {
      final days = [
        TripDay(dayNumber: 1, stops: [
          const TripStop(spotId: 'a', name: 'A', lat: 0, lng: 0, categoryId: 'museum', durationMinutes: 120),
          const TripStop(spotId: 'b', name: 'B', lat: 0, lng: 0, categoryId: 'food', durationMinutes: 75),
        ]),
      ];
      final stops = TripEstimator.schedule(days, gapMinutes: 60).first.stops;
      // 09:00 + 120min visit + 30min travel + 60min rest = 12:30
      expect(stops[1].suggestedTime, '12:30');
    });

    test('waits for a pinned stop and flows later stops after it', () {
      final days = [
        TripDay(dayNumber: 1, stops: [
          const TripStop(spotId: 'a', name: 'A', lat: 0, lng: 0, categoryId: 'viewpoint', durationMinutes: 45),
          const TripStop(spotId: 'b', name: 'B', lat: 0, lng: 0, categoryId: 'museum', durationMinutes: 120, pinnedTime: '16:00'),
          const TripStop(spotId: 'c', name: 'C', lat: 0, lng: 0, categoryId: 'food', durationMinutes: 75),
        ]),
      ];
      final stops = TripEstimator.schedule(days).first.stops;
      expect(stops[0].suggestedTime, '09:00');
      // The pinned museum waits until its 16:00 anchor…
      expect(stops[1].suggestedTime, '16:00');
      expect(stops[1].dayPart, DayPart.afternoon);
      // …and the stop after it shifts accordingly: 16:00 + 120 + 30 = 18:30.
      expect(stops[2].suggestedTime, '18:30');
      expect(stops[2].dayPart, DayPart.evening);
    });

    test('ignores an invalid pinnedTime', () {
      final days = [
        TripDay(dayNumber: 1, stops: [
          const TripStop(spotId: 'a', name: 'A', lat: 0, lng: 0, categoryId: 'museum', durationMinutes: 60, pinnedTime: 'late'),
        ]),
      ];
      final stops = TripEstimator.schedule(days).first.stops;
      expect(stops.first.suggestedTime, '09:00');
    });
  });

  group('TripEstimator.total', () {
    test('is stop spend plus daily meals & transport', () {
      final days = [
        TripDay(dayNumber: 1, stops: [
          const TripStop(spotId: 'a', name: 'A', lat: 0, lng: 0, estimatedCost: 25),
          const TripStop(spotId: 'b', name: 'B', lat: 0, lng: 0, estimatedCost: 10),
        ]),
      ];
      // stops 35 + balanced extras (15 transport + 18 meals) = 68
      expect(TripEstimator.total(days, pace: TripPace.balanced), 68);
    });
  });

  group('LocalItineraryGenerator', () {
    test('produces a scheduled, costed, in-destination trip', () {
      final spots = [
        _spot('s1', 'landmark', PriceRange.budget),
        _spot('s2', 'museum', PriceRange.moderate),
        _spot('s3', 'food', PriceRange.budget),
        _spot('far', 'beach', PriceRange.premium, city: 'Berlin'),
      ];
      final req = AiPlanRequest(
        destination: 'Cairo',
        country: 'Egypt',
        startDate: DateTime(2026, 7, 1),
        dayCount: 1,
        interests: const ['History'],
        budgetCap: 200,
      );

      final trip = LocalItineraryGenerator().generate(req, spots, 'u1');

      expect(trip.days, isNotEmpty);
      expect(trip.estimatedCost, greaterThan(0));
      expect(trip.budgetCap, 200);
      // First stop is scheduled to a real time and is a Cairo spot, not Berlin.
      final first = trip.days.first.stops.first;
      expect(first.suggestedTime, '09:00');
      expect(first.spotId, isNot('far'));
    });
  });
}
