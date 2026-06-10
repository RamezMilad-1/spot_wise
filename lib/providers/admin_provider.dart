import 'package:flutter/foundation.dart';

import '../core/utils/error_handler.dart';
import '../models/app_user.dart';
import '../models/enums.dart';
import '../models/notification_item.dart';
import '../models/report.dart';
import '../models/spot.dart';
import '../services/service_locator.dart';

/// The moderation workflow: the pending queue, approve / reject / verify / edit
/// / delete, and the reports inbox. Every decision queues a notification to the
/// submitter (card-free auto-notify).
class AdminProvider extends ChangeNotifier {
  List<Spot> _pending = [];
  List<Spot> _allSpots = [];
  List<AppUser> _users = [];
  List<Report> _reports = [];
  bool _loading = false;
  bool _loadingAll = false;
  bool _loadingUsers = false;
  String? _error;

  List<Spot> get pending => _pending;
  List<Spot> get allSpots => _allSpots;
  List<AppUser> get users => _users;
  bool get loadingUsers => _loadingUsers;
  int get userCount => _users.length;
  int get adminCount => _users.where((u) => u.isAdmin).length;
  int get suspendedCount => _users.where((u) => u.suspended).length;
  List<Report> get reports => _reports;
  List<Report> get openReports =>
      _reports.where((r) => r.status == ReportStatus.open).toList();
  bool get loading => _loading;
  bool get loadingAll => _loadingAll;
  String? get error => _error;
  int get pendingCount => _pending.length;
  int get openReportCount => openReports.length;

  int get approvedCount =>
      _allSpots.where((s) => s.status == SpotStatus.approved).length;
  int get rejectedCount =>
      _allSpots.where((s) => s.status == SpotStatus.rejected).length;
  int get featuredCount => _allSpots.where((s) => s.featured).length;

  /// Spot counts per category id, highest first — for the dashboard analytics.
  List<MapEntry<String, int>> get categoryBreakdown {
    final counts = <String, int>{};
    for (final s in _allSpots.where((s) => s.status == SpotStatus.approved)) {
      counts[s.categoryId] = (counts[s.categoryId] ?? 0) + 1;
    }
    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries;
  }

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    try {
      _pending = await services.backend.getSpots(status: SpotStatus.pending);
      _reports = await services.backend.getReports();
      _error = null;
    } catch (e) {
      _error = friendlyError(e);
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> approve(Spot spot) async {
    final updated = spot.copyWith(
      status: SpotStatus.approved,
      verified: true,
      approvedBy: services.auth.currentUser?.id,
    );
    await services.backend.updateSpot(updated);
    await _notify(
      spot.submittedBy,
      NotificationType.spotApproved,
      'Your spot was approved 🎉',
      '"${spot.name}" is now live on SpotWise for everyone to discover.',
      spotId: spot.id,
    );
    _pending.removeWhere((s) => s.id == spot.id);
    notifyListeners();
  }

  Future<void> reject(Spot spot, String reason) async {
    final updated = spot.copyWith(
      status: SpotStatus.rejected,
      rejectionReason: reason,
    );
    await services.backend.updateSpot(updated);
    await _notify(
      spot.submittedBy,
      NotificationType.spotRejected,
      'Your spot needs changes',
      '"${spot.name}" wasn\'t approved: $reason',
      spotId: spot.id,
    );
    _pending.removeWhere((s) => s.id == spot.id);
    notifyListeners();
  }

  /// Loads every spot (all statuses) for the "Manage all spots" screen.
  Future<void> loadAllSpots() async {
    _loadingAll = true;
    notifyListeners();
    try {
      _allSpots = await services.backend.getSpots();
      _error = null;
    } catch (e) {
      _error = friendlyError(e);
    }
    _loadingAll = false;
    notifyListeners();
  }

  Future<void> deleteSpot(Spot spot) async {
    await services.backend.deleteSpot(spot.id);
    _pending.removeWhere((s) => s.id == spot.id);
    _allSpots.removeWhere((s) => s.id == spot.id);
    notifyListeners();
  }

  Future<void> saveEdits(Spot spot) async {
    await services.backend.updateSpot(spot);
    _replace(spot);
    notifyListeners();
  }

  Future<void> toggleFeatured(Spot spot) =>
      saveEdits(spot.copyWith(featured: !spot.featured));

  Future<void> toggleVerified(Spot spot) =>
      saveEdits(spot.copyWith(verified: !spot.verified));

  void _replace(Spot spot) {
    final i = _allSpots.indexWhere((s) => s.id == spot.id);
    if (i >= 0) _allSpots[i] = spot;
    final j = _pending.indexWhere((s) => s.id == spot.id);
    if (j >= 0) _pending[j] = spot;
  }

  // ── User management ──────────────────────────────────────────────────────
  Future<void> loadUsers() async {
    _loadingUsers = true;
    notifyListeners();
    try {
      _users = await services.backend.getUsers();
      _error = null;
    } catch (e) {
      _error = friendlyError(e);
    }
    _loadingUsers = false;
    notifyListeners();
  }

  Future<void> setUserRole(AppUser user, UserRole role) async {
    final updated = user.copyWith(role: role);
    await services.backend.saveUser(updated);
    _replaceUser(updated);
    await _notify(
      user.id,
      NotificationType.system,
      role == UserRole.admin
          ? 'You\'re now an admin 🎉'
          : 'Your role was updated',
      role == UserRole.admin
          ? 'You can now moderate spots and manage SpotWise.'
          : 'Your account is now a standard Explorer.',
    );
    notifyListeners();
  }

  Future<void> toggleSuspended(AppUser user) async {
    final updated = user.copyWith(suspended: !user.suspended);
    await services.backend.saveUser(updated);
    _replaceUser(updated);
    await _notify(
      user.id,
      NotificationType.system,
      updated.suspended
          ? 'Your account was suspended'
          : 'Your account was reinstated',
      updated.suspended
          ? 'You can\'t sign in until an admin reinstates your account.'
          : 'Welcome back — you can sign in again.',
    );
    notifyListeners();
  }

  Future<void> deleteUser(AppUser user) async {
    await services.backend.deleteUser(user.id);
    _users.removeWhere((u) => u.id == user.id);
    notifyListeners();
  }

  Future<void> notifyUser(AppUser user, String title, String body) =>
      _notify(user.id, NotificationType.system, title, body);

  Future<void> notifyAllUsers(String title, String body) async {
    for (final u in _users) {
      await _notify(u.id, NotificationType.system, title, body);
    }
  }

  void _replaceUser(AppUser user) {
    final i = _users.indexWhere((u) => u.id == user.id);
    if (i >= 0) _users[i] = user;
  }

  Future<void> resolveReport(Report report, ReportStatus status) async {
    final updated = report.copyWith(status: status);
    await services.backend.updateReport(updated);
    final i = _reports.indexWhere((r) => r.id == report.id);
    if (i >= 0) _reports[i] = updated;
    notifyListeners();
  }

  Future<void> _notify(
    String userId,
    NotificationType type,
    String title,
    String body, {
    String? spotId,
  }) async {
    if (userId.isEmpty) return;
    await services.backend.addNotification(
      NotificationItem(
        id: '',
        userId: userId,
        title: title,
        body: body,
        type: type,
        spotId: spotId,
        createdAt: DateTime.now(),
      ),
    );
  }
}
