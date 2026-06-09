import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config/app_config.dart';
import '../../core/utils/app_exception.dart';
import '../../models/app_user.dart';
import '../../models/enums.dart';
import '../../models/notification_item.dart';
import '../../models/report.dart';
import '../../models/review.dart';
import '../../models/spot.dart';
import '../../models/trip.dart';
import 'backend_service.dart';

/// Firebase Realtime Database client built on raw HTTP + `dart:convert` — the
/// exact pattern the course taught (no `firebase_database` SDK, so it compiles
/// and ships with zero platform config).
///
/// It is inert until `FIREBASE_DB_URL` is set in `.env`; at that point
/// [ServiceLocator] selects it automatically in place of the local backend.
/// Wiring is complete — only the database URL (an account-setup step) is
/// intentionally deferred.
class FirebaseRestBackendService implements BackendService {
  final http.Client _client;
  FirebaseRestBackendService({http.Client? client})
      : _client = client ?? http.Client();

  String get _base {
    final url = AppConfig.firebaseDbUrl;
    if (url.isEmpty) {
      throw const NotConfiguredException(
        'Firebase Realtime Database is not configured. Add FIREBASE_DB_URL to .env '
        '(see Settings → Integrations).',
      );
    }
    return url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }

  Uri _uri(String path) => Uri.parse('$_base/$path.json');

  @override
  Future<void> init() async {
    // Nothing to warm up for the REST client.
  }

  // ── Low-level REST helpers ───────────────────────────────────────────────
  Future<Map<String, dynamic>> _getCollection(String path) async {
    final res = await _client.get(_uri(path));
    if (res.statusCode != 200) throw ServerException();
    final body = jsonDecode(res.body);
    if (body == null) return {};
    return Map<String, dynamic>.from(body as Map);
  }

  Future<Map<dynamic, dynamic>?> _getOne(String path) async {
    final res = await _client.get(_uri(path));
    if (res.statusCode != 200) throw ServerException();
    final body = jsonDecode(res.body);
    if (body == null) return null;
    return Map<dynamic, dynamic>.from(body as Map);
  }

  Future<String> _post(String path, Map<String, dynamic> data) async {
    final res = await _client.post(_uri(path), body: jsonEncode(data));
    if (res.statusCode < 200 || res.statusCode >= 300) throw ServerException();
    return (jsonDecode(res.body) as Map)['name'].toString();
  }

  Future<void> _put(String path, Map<String, dynamic> data) async {
    final res = await _client.put(_uri(path), body: jsonEncode(data));
    if (res.statusCode < 200 || res.statusCode >= 300) throw ServerException();
  }

  Future<void> _patch(String path, Map<String, dynamic> data) async {
    final res = await _client.patch(_uri(path), body: jsonEncode(data));
    if (res.statusCode < 200 || res.statusCode >= 300) throw ServerException();
  }

  Future<void> _delete(String path) async {
    final res = await _client.delete(_uri(path));
    if (res.statusCode < 200 || res.statusCode >= 300) throw ServerException();
  }

  List<T> _mapCollection<T>(
    Map<String, dynamic> raw,
    T Function(String id, Map json) fromJson,
  ) {
    return raw.entries
        .where((e) => e.value is Map)
        .map((e) => fromJson(e.key, Map<dynamic, dynamic>.from(e.value as Map)))
        .toList();
  }

  // ── Spots ────────────────────────────────────────────────────────────────
  @override
  Future<List<Spot>> getSpots({SpotStatus? status}) async {
    var list = _mapCollection(await _getCollection('spots'), Spot.fromJson);
    if (status != null) list = list.where((s) => s.status == status).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  @override
  Future<Spot?> getSpot(String id) async {
    final raw = await _getOne('spots/$id');
    return raw == null ? null : Spot.fromJson(id, raw);
  }

  @override
  Future<String> createSpot(Spot spot) async {
    if (spot.id.isEmpty) return _post('spots', spot.toJson());
    await _put('spots/${spot.id}', spot.toJson());
    return spot.id;
  }

  @override
  Future<void> updateSpot(Spot spot) => _put('spots/${spot.id}', spot.toJson());

  @override
  Future<void> deleteSpot(String id) => _delete('spots/$id');

  // ── Reviews ────────────────────────────────────────────────────────────
  @override
  Future<List<Review>> getReviews(String spotId) async {
    final list = _mapCollection(await _getCollection('reviews'), Review.fromJson)
        .where((r) => r.spotId == spotId)
        .toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  @override
  Future<String> addReview(Review review) async {
    if (review.id.isEmpty) return _post('reviews', review.toJson());
    await _put('reviews/${review.id}', review.toJson());
    return review.id;
  }

  // ── Trips ──────────────────────────────────────────────────────────────
  @override
  Future<List<Trip>> getTrips(String userId) async {
    final list = _mapCollection(await _getCollection('trips'), Trip.fromJson)
        .where((t) => t.userId == userId)
        .toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  @override
  Future<String> saveTrip(Trip trip) async {
    if (trip.id.isEmpty) return _post('trips', trip.toJson());
    await _put('trips/${trip.id}', trip.toJson());
    return trip.id;
  }

  @override
  Future<void> deleteTrip(String id) => _delete('trips/$id');

  // ── Notifications ──────────────────────────────────────────────────────
  @override
  Future<List<NotificationItem>> getNotifications(String userId) async {
    final list =
        _mapCollection(await _getCollection('notifications'), NotificationItem.fromJson)
            .where((n) => n.userId == userId)
            .toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  @override
  Future<void> addNotification(NotificationItem notification) async {
    if (notification.id.isEmpty) {
      await _post('notifications', notification.toJson());
    } else {
      await _put('notifications/${notification.id}', notification.toJson());
    }
  }

  @override
  Future<void> markNotificationRead(String id) =>
      _patch('notifications/$id', {'isRead': true});

  @override
  Future<void> markAllNotificationsRead(String userId) async {
    final all =
        _mapCollection(await _getCollection('notifications'), NotificationItem.fromJson);
    for (final n in all.where((n) => n.userId == userId && !n.isRead)) {
      await _patch('notifications/${n.id}', {'isRead': true});
    }
  }

  // ── Reports ────────────────────────────────────────────────────────────
  @override
  Future<List<Report>> getReports() async {
    final list = _mapCollection(await _getCollection('reports'), Report.fromJson);
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  @override
  Future<String> addReport(Report report) async {
    if (report.id.isEmpty) return _post('reports', report.toJson());
    await _put('reports/${report.id}', report.toJson());
    return report.id;
  }

  @override
  Future<void> updateReport(Report report) =>
      _patch('reports/${report.id}', {'status': report.status.value});

  // ── Users ──────────────────────────────────────────────────────────────
  @override
  Future<AppUser?> getUser(String id) async {
    final raw = await _getOne('users/$id');
    return raw == null ? null : AppUser.fromJson(id, raw);
  }

  @override
  Future<List<AppUser>> getUsers() async {
    final list = _mapCollection(await _getCollection('users'), AppUser.fromJson);
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  @override
  Future<void> saveUser(AppUser user) => _put('users/${user.id}', user.toJson());

  @override
  Future<void> deleteUser(String id) => _delete('users/$id');
}
