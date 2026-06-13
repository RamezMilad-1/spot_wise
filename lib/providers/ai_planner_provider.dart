import 'package:flutter/foundation.dart';

import '../core/utils/error_handler.dart';
import '../models/enums.dart';
import '../models/itinerary.dart';
import '../models/spot.dart';
import '../models/trip.dart';
import '../services/location/geocoding_service.dart';
import '../services/service_locator.dart';

/// Drives the AI planner wizard: collects the brief, calls the [AiService] and
/// holds the resulting [Trip].
class AiPlannerProvider extends ChangeNotifier {
  static const List<String> suggestedInterests = [
    'Food',
    'History',
    'Art',
    'Nature',
    'Views',
    'Nightlife',
    'Shopping',
    'Family',
    'Hidden gems',
    'Adventure',
    'Coffee',
    'Architecture',
  ];

  String destination = '';
  String country = '';
  double? lat;
  double? lng;
  DateTime startDate = DateTime.now().add(const Duration(days: 7));
  int dayCount = 3;
  final Set<String> interests = {'Food', 'Views'};
  PriceRange budget = PriceRange.moderate;
  TripPace pace = TripPace.balanced;
  double? budgetCap;
  String notes = '';

  bool _generating = false;
  String? _error;
  Trip? _result;
  (int, int)? _swapping;

  bool get generating => _generating;
  String? get error => _error;
  Trip? get result => _result;

  /// (dayIndex, stopIndex) of the stop being AI-swapped right now, if any.
  (int, int)? get swapping => _swapping;
  bool get isLive => services.ai.isLive;
  bool get canGenerate => destination.trim().isNotEmpty;

  void setDestinationText(String value) {
    destination = value;
    lat = null;
    lng = null;
    notifyListeners();
  }

  /// Pre-fills the brief from elsewhere in the app (e.g. the home page's
  /// "Plan a trip to …" banner).
  void prefillDestination({required String destination, String country = ''}) {
    this.destination = destination;
    this.country = country;
    lat = null;
    lng = null;
    notifyListeners();
  }

  void setDestinationFromPlace(GeoResult place) {
    destination = place.name;
    country = place.country;
    lat = place.lat;
    lng = place.lng;
    notifyListeners();
  }

  void setDays(int days) {
    dayCount = days.clamp(1, 14);
    notifyListeners();
  }

  void setStartDate(DateTime date) {
    startDate = date;
    notifyListeners();
  }

  void toggleInterest(String interest) {
    interests.contains(interest)
        ? interests.remove(interest)
        : interests.add(interest);
    notifyListeners();
  }

  void setBudget(PriceRange value) {
    budget = value;
    notifyListeners();
  }

  void setPace(TripPace value) {
    pace = value;
    notifyListeners();
  }

  void setBudgetCap(double? value) {
    budgetCap = (value != null && value > 0) ? value : null;
    notifyListeners();
  }

  void setNotes(String value) {
    notes = value;
    notifyListeners();
  }

  Future<bool> generate(List<Spot> spots) async {
    if (!canGenerate) {
      _error = 'Tell us where you\'re going first.';
      notifyListeners();
      return false;
    }
    _generating = true;
    _error = null;
    _result = null;
    notifyListeners();
    try {
      final request = AiPlanRequest(
        destination: destination.trim(),
        country: country,
        lat: lat,
        lng: lng,
        startDate: startDate,
        dayCount: dayCount,
        interests: interests.toList(),
        budget: budget,
        pace: pace,
        budgetCap: budgetCap,
        notes: notes.trim(),
      );
      _result = await services.ai.generateItinerary(
        request: request,
        spots: spots,
        userId: services.auth.currentUser?.id ?? 'guest',
      );
      _generating = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = friendlyError(e);
      _generating = false;
      notifyListeners();
      return false;
    }
  }

  /// Swaps one stop of [trip] for an AI-chosen alternative; the day re-flows
  /// around it. Returns the updated trip, or null on failure.
  Future<Trip?> replaceStop({
    required Trip trip,
    required int dayIndex,
    required int stopIndex,
    required List<Spot> spots,
  }) async {
    if (_swapping != null) return null;
    _swapping = (dayIndex, stopIndex);
    notifyListeners();
    try {
      final updated = await services.ai.replaceStop(
        trip: trip,
        dayIndex: dayIndex,
        stopIndex: stopIndex,
        spots: spots,
        notes: notes.trim(),
      );
      _result = updated;
      return updated;
    } catch (e) {
      _error = friendlyError(e);
      return null;
    } finally {
      _swapping = null;
      notifyListeners();
    }
  }

  void reset() {
    _result = null;
    _error = null;
    notifyListeners();
  }
}
