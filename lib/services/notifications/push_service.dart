import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../../models/enums.dart';
import '../../models/notification_item.dart';
import '../service_locator.dart';
import 'local_notification_service.dart';

/// Top-level FCM background handler (runs in its own isolate). When a message
/// carries a `notification` block, Android shows it in the tray automatically,
/// so there's nothing to do here — but the handler must exist and be top-level.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {}

/// Firebase Cloud Messaging wrapper. Android-only — on web/desktop every method
/// is a safe no-op, so the rest of the app stays platform-agnostic.
///
/// Foreground messages are surfaced through [LocalNotificationService] (FCM
/// doesn't show a banner while the app is open); taps are routed via [onOpen].
class PushService {
  PushService(this._local);
  final LocalNotificationService _local;

  /// Set by the app to route a notification tap (receives the message `data`).
  void Function(Map<String, dynamic> data)? onOpen;

  static bool get _supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Initialises Firebase and registers the background handler. Call once in
  /// `main()` before the app needs messaging.
  static Future<void> bootstrap() async {
    if (!_supported) return;
    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    } catch (_) {
      /* never block startup */
    }
  }

  /// Permission, foreground + tap listeners, and the broadcast topic. Call once
  /// after [bootstrap].
  Future<void> init() async {
    if (!_supported) return;
    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission();

      // Printed so you can paste it into Firebase Console → "Send test message".
      debugPrint('🔔 FCM token: ${await messaging.getToken()}');

      FirebaseMessaging.onMessage.listen((m) {
        _persist(m);
        final n = m.notification;
        if (n != null) _local.show(n.title ?? 'SpotWise', n.body ?? '');
      });

      FirebaseMessaging.onMessageOpenedApp.listen((m) {
        _persist(m);
        onOpen?.call(m.data);
      });
      final initial = await messaging.getInitialMessage();
      if (initial != null) {
        _persist(initial);
        onOpen?.call(initial.data);
      }

      // Lets admins broadcast from the Firebase console (target topic `all`).
      await messaging.subscribeToTopic('all');
    } catch (_) {
      /* best effort */
    }
  }

  /// Mirrors an incoming push into the signed-in user's in-app notification
  /// center so the bell + list stay in sync with what was pushed. No-op for
  /// guests (notifications are per-user).
  Future<void> _persist(RemoteMessage m) async {
    try {
      final user = services.auth.currentUser;
      if (user == null) return;
      final n = m.notification;
      final title = n?.title ?? m.data['title']?.toString() ?? 'SpotWise';
      final body = n?.body ?? m.data['body']?.toString() ?? '';
      await services.backend.addNotification(
        NotificationItem(
          id: '',
          userId: user.id,
          title: title,
          body: body,
          type: NotificationType.system,
          spotId: m.data['spotId']?.toString(),
          createdAt: DateTime.now(),
        ),
      );
    } catch (_) {
      /* best effort */
    }
  }

  /// The device's current FCM token, or null when unsupported/unavailable.
  Future<String?> currentToken() async {
    if (!_supported) return null;
    try {
      return await FirebaseMessaging.instance.getToken();
    } catch (_) {
      return null;
    }
  }
}
