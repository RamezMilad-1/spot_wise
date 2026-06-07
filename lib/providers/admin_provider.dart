import 'package:flutter/foundation.dart';

import '../core/utils/error_handler.dart';
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
  List<Report> _reports = [];
  bool _loading = false;
  String? _error;

  List<Spot> get pending => _pending;
  List<Report> get reports => _reports;
  List<Report> get openReports =>
      _reports.where((r) => r.status == ReportStatus.open).toList();
  bool get loading => _loading;
  String? get error => _error;
  int get pendingCount => _pending.length;
  int get openReportCount => openReports.length;

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
    final updated = spot.copyWith(status: SpotStatus.rejected, rejectionReason: reason);
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

  Future<void> deleteSpot(Spot spot) async {
    await services.backend.deleteSpot(spot.id);
    _pending.removeWhere((s) => s.id == spot.id);
    notifyListeners();
  }

  Future<void> saveEdits(Spot spot) async {
    await services.backend.updateSpot(spot);
    final i = _pending.indexWhere((s) => s.id == spot.id);
    if (i >= 0) _pending[i] = spot;
    notifyListeners();
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
    await services.backend.addNotification(NotificationItem(
      id: '',
      userId: userId,
      title: title,
      body: body,
      type: type,
      spotId: spotId,
      createdAt: DateTime.now(),
    ));
  }
}
