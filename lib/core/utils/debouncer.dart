import 'dart:async';

import 'package:flutter/foundation.dart';

/// Delays an action until the user stops triggering it — used for search-as-
/// you-type so we don't hit Nominatim on every keystroke.
class Debouncer {
  final Duration delay;
  Timer? _timer;

  Debouncer({this.delay = const Duration(milliseconds: 450)});

  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  void dispose() => _timer?.cancel();
}
