import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/categories.dart';

/// Lets admins enable/disable categories (managed in the admin panel). Disabled
/// categories drop out of the Add-Spot picker and the map filters. Persisted in
/// SharedPreferences.
class CategoryStore extends ChangeNotifier {
  static const _key = 'disabled_categories';
  Set<String> _disabled = {};

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _disabled = (prefs.getStringList(_key) ?? const []).toSet();
    notifyListeners();
  }

  List<SpotCategory> get enabled =>
      Categories.all.where((c) => !_disabled.contains(c.id)).toList();

  bool isEnabled(String id) => !_disabled.contains(id);

  Future<void> toggle(String id) async {
    if (_disabled.contains(id)) {
      _disabled.remove(id);
    } else {
      _disabled.add(id);
    }
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, _disabled.toList());
  }
}
