import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

import '../models/spot.dart';
import '../models/spot_filter.dart';
import '../services/location/geocoding_service.dart';
import '../services/location/location_service.dart';
import '../services/service_locator.dart';

/// State for the discovery map: active filters, camera target, the user's
/// location and the city-search results.
class MapProvider extends ChangeNotifier {
  SpotFilter _filter = const SpotFilter();
  LatLng _center = LocationService.fallbackCenter;
  double _zoom = 11.5;
  String? _selectedSpotId;
  LatLng? _userLocation;
  int _moveTick = 0;

  List<GeoResult> _searchResults = const [];
  bool _searching = false;

  SpotFilter get filter => _filter;
  LatLng get center => _center;
  double get zoom => _zoom;
  String? get selectedSpotId => _selectedSpotId;
  LatLng? get userLocation => _userLocation;

  /// Increments whenever the camera target changes, so the map widget knows to
  /// animate the controller to [center]/[zoom].
  int get moveTick => _moveTick;

  List<GeoResult> get searchResults => _searchResults;
  bool get searching => _searching;

  void setFilter(SpotFilter filter) {
    _filter = filter;
    notifyListeners();
  }

  void updateQuery(String query) {
    _filter = _filter.copyWith(query: query);
    notifyListeners();
  }

  void clearFilters() {
    _filter = const SpotFilter();
    notifyListeners();
  }

  void select(String? spotId) {
    _selectedSpotId = spotId;
    notifyListeners();
  }

  void moveTo(LatLng center, {double? zoom}) {
    _center = center;
    if (zoom != null) _zoom = zoom;
    _moveTick++;
    notifyListeners();
  }

  Future<void> locateMe() async {
    final location = await services.location.getCurrent();
    if (location != null) {
      _userLocation = location;
      moveTo(location, zoom: 13);
    }
  }

  Future<void> search(String query) async {
    _searching = true;
    notifyListeners();
    try {
      _searchResults = await services.geocoding.search(query);
    } catch (_) {
      _searchResults = const [];
    }
    _searching = false;
    notifyListeners();
  }

  void clearSearch() {
    _searchResults = const [];
    notifyListeners();
  }

  void goToPlace(GeoResult place) {
    _searchResults = const [];
    _filter = _filter.copyWith(query: place.name);
    moveTo(place.latLng, zoom: 12.5);
  }

  List<Spot> visible(List<Spot> all) =>
      all.where((s) => _filter.matches(s, origin: _userLocation)).toList();
}
