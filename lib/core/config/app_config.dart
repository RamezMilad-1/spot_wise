import 'env.dart';

/// Which implementation a service should use.
enum BackendMode { local, remote }

/// Central, read-only view of how the app is configured. The presence of a
/// value in `.env` automatically flips the relevant integration from the local
/// mock to the real remote one — no code change required.
class AppConfig {
  AppConfig._();

  // App identity ──────────────────────────────────────────────────────────
  static const String appName = 'SpotWise';
  static const String tagline = 'Discover · Plan · Personalise';
  static const String version = '1.0.0';

  // Free, no-key services that work right now ──────────────────────────────
  static const String osmTileUrl =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const String osmUserAgent = 'com.spotwise.app';
  static const String nominatimBase = 'https://nominatim.openstreetmap.org';
  static const String googleMapsSearch =
      'https://www.google.com/maps/search/?api=1&query=';
  static const String googleMapsDir =
      'https://www.google.com/maps/dir/?api=1&destination=';

  // Integration availability (derived from .env) ───────────────────────────
  static bool get hasFirebaseDb => Env.firebaseDbUrl.isNotEmpty;
  static bool get hasFirebaseAuth => Env.firebaseApiKey.isNotEmpty;
  static bool get hasGemini => Env.geminiApiKey.isNotEmpty;

  static BackendMode get backendMode =>
      hasFirebaseDb ? BackendMode.remote : BackendMode.local;
  static BackendMode get authMode =>
      hasFirebaseAuth ? BackendMode.remote : BackendMode.local;

  static String get firebaseDbUrl => Env.firebaseDbUrl;
  static String get firebaseApiKey => Env.firebaseApiKey;
  static String get geminiApiKey => Env.geminiApiKey;
}
