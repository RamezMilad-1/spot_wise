import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/demo_seed.dart';
import '../../models/app_user.dart';
import '../../models/enums.dart';
import '../../models/notification_item.dart';
import '../../models/report.dart';
import '../../models/review.dart';
import '../../models/spot.dart';
import '../../models/trip.dart';
import 'backend_service.dart';

/// Offline-first backend backed by Hive. Seeded once with [DemoSeed] so the
/// whole app is populated on first launch. All edits (approvals, new spots,
/// reviews, trips…) persist across restarts.
class LocalBackendService implements BackendService {
  static const _uuid = Uuid();
  static const Duration _latency = Duration(milliseconds: 280);

  late final Box _spots;
  late final Box _reviews;
  late final Box _trips;
  late final Box _notifications;
  late final Box _reports;
  late final Box _users;
  late final Box _meta;

  @override
  Future<void> init() async {
    _spots = await Hive.openBox('spots');
    _reviews = await Hive.openBox('reviews');
    _trips = await Hive.openBox('trips');
    _notifications = await Hive.openBox('notifications');
    _reports = await Hive.openBox('reports');
    _users = await Hive.openBox('users');
    _meta = await Hive.openBox('meta');

    if (_meta.get('seeded') != true) {
      await _seed();
      await _meta.put('seeded', true);
    }
  }

  Future<void> _seed() async {
    for (final s in DemoSeed.spots()) {
      await _spots.put(s.id, s.toJson());
    }
    for (final r in DemoSeed.reviews()) {
      await _reviews.put(r.id, r.toJson());
    }
    for (final t in DemoSeed.trips()) {
      await _trips.put(t.id, t.toJson());
    }
    for (final n in DemoSeed.notifications()) {
      await _notifications.put(n.id, n.toJson());
    }
    for (final u in DemoSeed.users()) {
      await _users.put(u.id, u.toJson());
    }
  }

  /// Wipes Hive and re-applies the demo seed (used by the in-app reset button).
  Future<void> reseed() async {
    await Future.wait([
      _spots.clear(),
      _reviews.clear(),
      _trips.clear(),
      _notifications.clear(),
      _reports.clear(),
      _users.clear(),
    ]);
    await _seed();
  }

  Map<dynamic, dynamic> _map(dynamic raw) =>
      Map<dynamic, dynamic>.from(raw as Map);

  List<T> _all<T>(Box box, T Function(String id, Map json) fromJson) =>
      box.keys.map((k) => fromJson(k.toString(), _map(box.get(k)))).toList();

  // ── Spots ──────────────────────────────────────────────────────────────
  @override
  Future<List<Spot>> getSpots({SpotStatus? status}) async {
    await Future.delayed(_latency);
    var list = _all(_spots, Spot.fromJson);
    if (status != null) list = list.where((s) => s.status == status).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  @override
  Future<Spot?> getSpot(String id) async {
    final raw = _spots.get(id);
    if (raw == null) return null;
    return Spot.fromJson(id, _map(raw));
  }

  @override
  Future<String> createSpot(Spot spot) async {
    final id = spot.id.isEmpty ? _uuid.v4() : spot.id;
    await _spots.put(id, spot.toJson());
    return id;
  }

  @override
  Future<void> updateSpot(Spot spot) => _spots.put(spot.id, spot.toJson());

  @override
  Future<void> deleteSpot(String id) => _spots.delete(id);

  // ── Reviews ────────────────────────────────────────────────────────────
  @override
  Future<List<Review>> getReviews(String spotId) async {
    await Future.delayed(_latency);
    final list = _all(
      _reviews,
      Review.fromJson,
    ).where((r) => r.spotId == spotId).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  @override
  Future<String> addReview(Review review) async {
    final id = review.id.isEmpty ? _uuid.v4() : review.id;
    await _reviews.put(id, review.toJson());
    return id;
  }

  // ── Trips ──────────────────────────────────────────────────────────────
  @override
  Future<List<Trip>> getTrips(String userId) async {
    await Future.delayed(_latency);
    final list = _all(
      _trips,
      Trip.fromJson,
    ).where((t) => t.userId == userId).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  @override
  Future<String> saveTrip(Trip trip) async {
    final id = trip.id.isEmpty ? _uuid.v4() : trip.id;
    await _trips.put(id, trip.toJson());
    return id;
  }

  @override
  Future<void> deleteTrip(String id) => _trips.delete(id);

  // ── Notifications ──────────────────────────────────────────────────────
  @override
  Future<List<NotificationItem>> getNotifications(String userId) async {
    final list = _all(
      _notifications,
      NotificationItem.fromJson,
    ).where((n) => n.userId == userId).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  @override
  Future<void> addNotification(NotificationItem notification) async {
    final id = notification.id.isEmpty ? _uuid.v4() : notification.id;
    await _notifications.put(id, notification.toJson());
  }

  @override
  Future<void> markNotificationRead(String id) async {
    final raw = _notifications.get(id);
    if (raw == null) return;
    final n = NotificationItem.fromJson(id, _map(raw)).copyWith(isRead: true);
    await _notifications.put(id, n.toJson());
  }

  @override
  Future<void> markAllNotificationsRead(String userId) async {
    for (final k in _notifications.keys) {
      final n = NotificationItem.fromJson(
        k.toString(),
        _map(_notifications.get(k)),
      );
      if (n.userId == userId && !n.isRead) {
        await _notifications.put(k, n.copyWith(isRead: true).toJson());
      }
    }
  }

  // ── Reports ────────────────────────────────────────────────────────────
  @override
  Future<List<Report>> getReports() async {
    await Future.delayed(_latency);
    final list = _all(_reports, Report.fromJson);
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  @override
  Future<String> addReport(Report report) async {
    final id = report.id.isEmpty ? _uuid.v4() : report.id;
    await _reports.put(id, report.toJson());
    return id;
  }

  @override
  Future<void> updateReport(Report report) =>
      _reports.put(report.id, report.toJson());

  // ── Users ──────────────────────────────────────────────────────────────
  @override
  Future<AppUser?> getUser(String id) async {
    final raw = _users.get(id);
    if (raw == null) return null;
    return AppUser.fromJson(id, _map(raw));
  }

  @override
  Future<List<AppUser>> getUsers() async {
    await Future.delayed(_latency);
    final list = _all(_users, AppUser.fromJson);
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  @override
  Future<void> saveUser(AppUser user) => _users.put(user.id, user.toJson());

  @override
  Future<void> deleteUser(String id) => _users.delete(id);
}
