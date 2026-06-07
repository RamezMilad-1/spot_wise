import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Safe accessors over the `.env` file. Every getter returns an empty string if
/// the file is missing or the key is unset, so reading config never throws and
/// the app can always boot on local mock data.
class Env {
  Env._();

  static String _read(String key) {
    try {
      return (dotenv.env[key] ?? '').trim();
    } catch (_) {
      // dotenv was never initialised (e.g. .env asset missing).
      return '';
    }
  }

  static String get firebaseDbUrl => _read('FIREBASE_DB_URL');
  static String get firebaseApiKey => _read('FIREBASE_API_KEY');
  static String get geminiApiKey => _read('GEMINI_API_KEY');
}
