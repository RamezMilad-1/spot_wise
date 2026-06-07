import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Tracks online/offline state so screens can show an offline banner and the
/// app can lean on cached/Hive data when the network drops.
class ConnectivityProvider extends ChangeNotifier {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _sub;
  bool _online = true;

  bool get isOnline => _online;

  Future<void> init() async {
    try {
      _online = _hasConnection(await _connectivity.checkConnectivity());
      _sub = _connectivity.onConnectivityChanged.listen((results) {
        final next = _hasConnection(results);
        if (next != _online) {
          _online = next;
          notifyListeners();
        }
      });
    } catch (_) {
      _online = true; // assume online if the platform can't tell us
    }
    notifyListeners();
  }

  bool _hasConnection(List<ConnectivityResult> results) =>
      results.isEmpty || results.any((r) => r != ConnectivityResult.none);

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
