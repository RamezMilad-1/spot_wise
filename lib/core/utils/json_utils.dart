/// Defensive JSON coercion helpers.
///
/// Firebase Realtime DB returns loosely-typed JSON (numbers can arrive as int,
/// double or String; lists are sometimes maps keyed by index). These helpers
/// keep every `fromJson` short and crash-proof.
class JsonUtils {
  JsonUtils._();

  static String asString(dynamic v, [String fallback = '']) =>
      v?.toString() ?? fallback;

  static String? asStringOrNull(dynamic v) => v?.toString();

  static double asDouble(dynamic v, [double fallback = 0]) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? fallback;
    return fallback;
  }

  static int asInt(dynamic v, [int fallback = 0]) {
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? fallback;
    return fallback;
  }

  static bool asBool(dynamic v, [bool fallback = false]) {
    if (v is bool) return v;
    if (v is num) return v != 0;
    if (v is String) return v.toLowerCase() == 'true';
    return fallback;
  }

  static List<String> asStringList(dynamic v) {
    if (v is List) return v.where((e) => e != null).map((e) => e.toString()).toList();
    if (v is Map) return v.values.where((e) => e != null).map((e) => e.toString()).toList();
    return <String>[];
  }

  static List<Map<String, dynamic>> asMapList(dynamic v) {
    if (v is List) {
      return v.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    }
    if (v is Map) {
      return v.values.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    }
    return <Map<String, dynamic>>[];
  }

  static DateTime asDate(dynamic v) {
    if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
    if (v is String) {
      final ms = int.tryParse(v);
      if (ms != null) return DateTime.fromMillisecondsSinceEpoch(ms);
      return DateTime.tryParse(v) ?? DateTime.now();
    }
    return DateTime.now();
  }
}
