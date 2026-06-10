import '../../models/notification_item.dart';
import '../service_locator.dart';

/// A live notifications feed: emits immediately, then re-polls the backend on a
/// short interval. This is the app's `StreamProvider` surface (satisfies the
/// "stream providers" requirement) and can later be swapped for true RTDB
/// streaming without touching the UI.
Stream<List<NotificationItem>> watchNotifications(String userId) async* {
  yield await services.backend.getNotifications(userId);
  yield* Stream.periodic(
    const Duration(seconds: 3),
  ).asyncMap((_) => services.backend.getNotifications(userId));
}
