import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// On-device notifications via `flutter_local_notifications`. 100% free, no FCM
/// account. No-ops on web (the plugin is mobile/desktop only) so the same code
/// runs everywhere.
///
/// FCM push (cross-device) is the deferred step documented in the Integrations
/// screen; in-app delivery still works via the notification center.
class LocalNotificationService {
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  Future<void> init() async {
    if (kIsWeb) return;
    try {
      const settings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
        macOS: DarwinInitializationSettings(),
      );
      await _plugin.initialize(settings);
      _ready = true;
    } catch (_) {
      _ready = false;
    }
  }

  /// Requests the OS notification permission (Android 13+/iOS/macOS).
  Future<void> requestPermission() async {
    if (kIsWeb || !_ready) return;
    try {
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    } catch (_) {/* best effort */}
  }

  Future<void> show(String title, String body) async {
    if (kIsWeb || !_ready) return;
    try {
      const details = NotificationDetails(
        android: AndroidNotificationDetails(
          'spotwise_default',
          'SpotWise',
          channelDescription: 'SpotWise updates and reminders',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
        macOS: DarwinNotificationDetails(),
      );
      await _plugin.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        details,
      );
    } catch (_) {/* best effort */}
  }
}
