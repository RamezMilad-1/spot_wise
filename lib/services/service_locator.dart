import '../core/config/app_config.dart';
import 'ai/ai_service.dart';
import 'ai/gemini_ai_service.dart';
import 'auth/auth_service.dart';
import 'auth/firebase_auth_rest_service.dart';
import 'auth/local_auth_service.dart';
import 'backend/backend_service.dart';
import 'backend/firebase_rest_backend_service.dart';
import 'backend/local_backend_service.dart';
import 'location/geocoding_service.dart';
import 'location/location_service.dart';
import 'media/photo_service.dart';
import 'notifications/local_notification_service.dart';
import 'notifications/push_service.dart';

/// Builds and holds the app's services, choosing the local mock or the real
/// remote implementation per integration based on `.env` (via [AppConfig]).
///
/// With an empty `.env` everything is local and the app runs fully offline-
/// capable with seeded data. Add a key/URL and the matching service swaps in
/// automatically — no other code changes.
class ServiceLocator {
  ServiceLocator._();
  static final ServiceLocator instance = ServiceLocator._();

  late final BackendService backend;
  late final AuthService auth;
  late final AiService ai;
  late final PhotoService photo;
  late final LocationService location;
  late final GeocodingService geocoding;
  late final LocalNotificationService notifications;
  late final PushService push;

  /// Kept as the concrete type so the UI can offer "reset demo data".
  LocalBackendService? _localBackend;
  LocalBackendService? get localBackend => _localBackend;

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    if (AppConfig.backendMode == BackendMode.remote) {
      backend = FirebaseRestBackendService();
    } else {
      _localBackend = LocalBackendService();
      backend = _localBackend!;
    }
    await backend.init();

    auth = AppConfig.authMode == BackendMode.remote
        ? FirebaseAuthRestService(backend)
        : LocalAuthService(backend);
    await auth.init();

    ai = GeminiAiService();
    photo = PhotoService();
    location = LocationService();
    geocoding = GeocodingService();
    notifications = LocalNotificationService();
    await notifications.init();
    push = PushService(notifications);

    _initialized = true;
  }
}

/// Convenient shorthand used across providers.
ServiceLocator get services => ServiceLocator.instance;
