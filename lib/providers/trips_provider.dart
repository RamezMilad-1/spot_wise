import 'package:flutter/foundation.dart';

import '../core/utils/error_handler.dart';
import '../models/enums.dart';
import '../models/spot.dart';
import '../models/trip.dart';
import '../services/service_locator.dart';

/// Loads the signed-in user's trips and provides the day-by-day editor
/// operations (add/remove/reorder stops, add days, mark complete).
class TripsProvider extends ChangeNotifier {
  List<Trip> _trips = [];
  bool _loading = false;
  String? _error;

  List<Trip> get trips => _trips;
  bool get loading => _loading;
  String? get error => _error;
  bool get isEmpty => _trips.isEmpty;

  List<Trip> get upcoming =>
      _trips.where((t) => !t.completed).toList();
  List<Trip> get completed =>
      _trips.where((t) => t.completed).toList();

  Future<void> load() async {
    final uid = services.auth.currentUser?.id;
    if (uid == null) {
      _trips = [];
      notifyListeners();
      return;
    }
    _loading = _trips.isEmpty;
    notifyListeners();
    try {
      _trips = await services.backend.getTrips(uid);
      _error = null;
    } catch (e) {
      _error = friendlyError(e);
    }
    _loading = false;
    notifyListeners();
  }

  Trip? byId(String id) {
    for (final t in _trips) {
      if (t.id == id) return t;
    }
    return null;
  }

  Future<String> createTrip(Trip trip) async {
    final id = await services.backend.saveTrip(trip);
    await load();
    return id;
  }

  Future<void> deleteTrip(String id) async {
    await services.backend.deleteTrip(id);
    _trips.removeWhere((t) => t.id == id);
    notifyListeners();
  }

  Future<void> toggleComplete(Trip trip) =>
      _persist(trip.copyWith(completed: !trip.completed));

  Future<void> addSpotToTrip(Trip trip, Spot spot, {int dayNumber = 1}) async {
    final days = [...trip.days];
    if (days.isEmpty) {
      days.add(TripDay(dayNumber: 1, date: trip.startDate));
    }
    var index = days.indexWhere((d) => d.dayNumber == dayNumber);
    if (index < 0) index = 0;

    final stop = TripStop(
      spotId: spot.id,
      name: spot.name,
      photo: spot.coverPhoto,
      categoryId: spot.categoryId,
      lat: spot.lat,
      lng: spot.lng,
      dayPart: _nextPart(days[index].stops.length),
      note: spot.bestTimeToVisit.isEmpty ? '' : 'Best around ${spot.bestTimeToVisit.toLowerCase()}.',
    );
    days[index] = days[index].copyWith(stops: [...days[index].stops, stop]);
    await _persist(trip.copyWith(days: days));
  }

  Future<void> removeStop(Trip trip, int dayNumber, int stopIndex) async {
    final days = [...trip.days];
    final di = days.indexWhere((d) => d.dayNumber == dayNumber);
    if (di < 0) return;
    final stops = [...days[di].stops];
    if (stopIndex < 0 || stopIndex >= stops.length) return;
    stops.removeAt(stopIndex);
    days[di] = days[di].copyWith(stops: stops);
    await _persist(trip.copyWith(days: days));
  }

  Future<void> reorderStops(Trip trip, int dayNumber, int oldIndex, int newIndex) async {
    final days = [...trip.days];
    final di = days.indexWhere((d) => d.dayNumber == dayNumber);
    if (di < 0) return;
    final stops = [...days[di].stops];
    if (newIndex > oldIndex) newIndex -= 1;
    final item = stops.removeAt(oldIndex);
    stops.insert(newIndex, item);
    days[di] = days[di].copyWith(stops: stops);
    await _persist(trip.copyWith(days: days));
  }

  Future<void> addDay(Trip trip) async {
    final nextNumber = trip.days.isEmpty ? 1 : trip.days.last.dayNumber + 1;
    final date = trip.startDate.add(Duration(days: nextNumber - 1));
    final days = [...trip.days, TripDay(dayNumber: nextNumber, date: date)];
    await _persist(trip.copyWith(days: days));
  }

  Future<void> updateNotes(Trip trip, String notes) =>
      _persist(trip.copyWith(notes: notes));

  Future<void> _persist(Trip updated) async {
    await services.backend.saveTrip(updated);
    final i = _trips.indexWhere((t) => t.id == updated.id);
    if (i >= 0) {
      _trips[i] = updated;
    } else {
      _trips.insert(0, updated);
    }
    notifyListeners();
  }

  DayPart _nextPart(int count) =>
      const [DayPart.morning, DayPart.afternoon, DayPart.evening][count % 3];
}
