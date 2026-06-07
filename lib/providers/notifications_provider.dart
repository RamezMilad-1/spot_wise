import 'package:flutter/foundation.dart';

import '../models/notification_item.dart';
import '../services/service_locator.dart';

/// Actions over the notification center (the live list itself comes from the
/// `StreamProvider` fed by [watchNotifications]).
class NotificationsProvider extends ChangeNotifier {
  Future<void> markRead(String id) async {
    await services.backend.markNotificationRead(id);
    notifyListeners();
  }

  Future<void> markAllRead() async {
    final uid = services.auth.currentUser?.id;
    if (uid == null) return;
    await services.backend.markAllNotificationsRead(uid);
    notifyListeners();
  }

  Future<void> add(NotificationItem notification) async {
    await services.backend.addNotification(notification);
    // Surface an OS notification too (no-op on web).
    await services.notifications.show(notification.title, notification.body);
    notifyListeners();
  }
}
