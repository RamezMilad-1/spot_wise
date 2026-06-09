import '../../models/app_user.dart';
import '../../models/enums.dart';
import '../../models/notification_item.dart';
import '../../models/report.dart';
import '../../models/review.dart';
import '../../models/spot.dart';
import '../../models/trip.dart';

/// The data contract for SpotWise. Screens never touch this directly — they go
/// through providers, which talk to whichever implementation is active:
///
///  * [LocalBackendService]            — Hive + demo seed (default, zero setup)
///  * [FirebaseRestBackendService]     — Realtime DB over HTTP (auto-activated
///                                       when `FIREBASE_DB_URL` is set in .env)
abstract class BackendService {
  Future<void> init();

  // ── Spots ──────────────────────────────────────────────────────────────
  Future<List<Spot>> getSpots({SpotStatus? status});
  Future<Spot?> getSpot(String id);
  Future<String> createSpot(Spot spot);
  Future<void> updateSpot(Spot spot);
  Future<void> deleteSpot(String id);

  // ── Reviews ────────────────────────────────────────────────────────────
  Future<List<Review>> getReviews(String spotId);
  Future<String> addReview(Review review);

  // ── Trips ──────────────────────────────────────────────────────────────
  Future<List<Trip>> getTrips(String userId);
  Future<String> saveTrip(Trip trip);
  Future<void> deleteTrip(String id);

  // ── Notifications ──────────────────────────────────────────────────────
  Future<List<NotificationItem>> getNotifications(String userId);
  Future<void> addNotification(NotificationItem notification);
  Future<void> markNotificationRead(String id);
  Future<void> markAllNotificationsRead(String userId);

  // ── Reports ────────────────────────────────────────────────────────────
  Future<List<Report>> getReports();
  Future<String> addReport(Report report);
  Future<void> updateReport(Report report);

  // ── Users ──────────────────────────────────────────────────────────────
  Future<AppUser?> getUser(String id);
  Future<List<AppUser>> getUsers();
  Future<void> saveUser(AppUser user);
  Future<void> deleteUser(String id);
}
