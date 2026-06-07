import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/categories.dart';
import '../core/utils/error_handler.dart';
import '../models/app_user.dart';
import '../models/enums.dart';
import '../models/spot.dart';
import '../services/service_locator.dart';

/// Loads and caches the approved-spots feed, handles new submissions, and
/// powers the home "Recommended for you" ranking.
class SpotsProvider extends ChangeNotifier {
  static const _cacheKey = 'cache_spots';

  List<Spot> _spots = [];
  bool _loading = false;
  String? _error;

  List<Spot> get spots => _spots;
  bool get loading => _loading;
  String? get error => _error;
  bool get isEmpty => _spots.isEmpty;

  Future<void> load({bool force = false}) async {
    if (_spots.isEmpty) {
      // Show cached data instantly while the network call runs.
      final cached = await _readCache();
      if (cached.isNotEmpty) {
        _spots = cached;
        notifyListeners();
      }
    }
    _loading = _spots.isEmpty;
    _error = null;
    notifyListeners();

    try {
      final fresh = await services.backend.getSpots(status: SpotStatus.approved);
      _spots = fresh;
      _loading = false;
      notifyListeners();
      await _writeCache(fresh);
    } catch (e) {
      _error = friendlyError(e);
      _loading = false;
      notifyListeners();
    }
  }

  Spot? byId(String id) {
    for (final s in _spots) {
      if (s.id == id) return s;
    }
    return null;
  }

  Future<Spot?> fetchById(String id) async =>
      byId(id) ?? await services.backend.getSpot(id);

  /// Submits a new (pending) spot. It won't appear in the approved feed until
  /// an admin approves it.
  Future<void> submitSpot(Spot spot) => services.backend.createSpot(spot);

  /// Cities present in the data, for the discovery/search chips.
  List<String> get cities {
    final set = <String>{};
    for (final s in _spots) {
      if (s.city.isNotEmpty) set.add(s.city);
    }
    final list = set.toList()..sort();
    return list;
  }

  List<Spot> byCategory(String categoryId) =>
      _spots.where((s) => s.categoryId == categoryId).toList();

  List<Spot> recommendationsFor(AppUser? user, {int limit = 8}) {
    final interests = (user?.interests ?? const []).map((e) => e.toLowerCase()).toSet();
    final saved = (user?.savedSpotIds ?? const []).toSet();
    int score(Spot s) {
      var sc = (s.rating * 10).round() + s.reviewCount ~/ 80;
      final hay = '${s.tags.join(' ')} ${Categories.labelFor(s.categoryId)}'.toLowerCase();
      for (final i in interests) {
        if (hay.contains(i)) sc += 30;
      }
      if (s.hiddenGem) sc += 6;
      if (saved.contains(s.id)) sc -= 200; // don't re-recommend saved spots
      return sc;
    }

    final list = [..._spots]..sort((a, b) => score(b).compareTo(score(a)));
    return list.take(limit).toList();
  }

  List<Spot> get trending {
    final list = [..._spots]
      ..sort((a, b) => (b.likeCount + b.saveCount).compareTo(a.likeCount + a.saveCount));
    return list.take(10).toList();
  }

  Future<void> _writeCache(List<Spot> spots) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = spots.map((s) => {'id': s.id, ...s.toJson()}).toList();
      await prefs.setString(_cacheKey, jsonEncode(data));
    } catch (_) {/* cache is best-effort */}
  }

  Future<List<Spot>> _readCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey);
      if (raw == null) return [];
      final list = jsonDecode(raw) as List;
      return list.map((e) {
        final m = Map<String, dynamic>.from(e as Map);
        return Spot.fromJson(m['id'].toString(), m);
      }).toList();
    } catch (_) {
      return [];
    }
  }
}
