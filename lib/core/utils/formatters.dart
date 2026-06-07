import 'package:intl/intl.dart';

/// Human-friendly formatting for dates, distances, ratings and counts.
class Formatters {
  Formatters._();

  static final DateFormat _full = DateFormat('MMM d, yyyy');
  static final DateFormat _short = DateFormat('MMM d');
  static final DateFormat _weekday = DateFormat('EEE, MMM d');
  static final DateFormat _time = DateFormat('h:mm a');

  static String date(DateTime d) => _full.format(d);
  static String dateShort(DateTime d) => _short.format(d);
  static String weekday(DateTime d) => _weekday.format(d);
  static String time(DateTime d) => _time.format(d);

  static String dateRange(DateTime start, DateTime end) {
    if (start.year == end.year && start.month == end.month) {
      return '${DateFormat('MMM d').format(start)} – ${DateFormat('d, yyyy').format(end)}';
    }
    return '${_short.format(start)} – ${_full.format(end)}';
  }

  static int nights(DateTime start, DateTime end) =>
      end.difference(start).inDays.clamp(0, 9999);

  static String relative(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
    return _short.format(d);
  }

  static String distance(double meters) {
    if (meters < 1000) return '${meters.round()} m';
    return '${(meters / 1000).toStringAsFixed(meters < 10000 ? 1 : 0)} km';
  }

  static String rating(double r) => r.toStringAsFixed(1);

  static String count(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return '$n';
  }
}
