import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/demo_seed.dart';
import '../../core/utils/app_exception.dart';
import '../../models/app_user.dart';
import '../../models/enums.dart';
import '../backend/backend_service.dart';
import 'auth_service.dart';

/// Email/password auth backed by Hive — no account or network needed.
///
/// User *records* live in the shared backend (`users`); this service only owns
/// credentials and the current session. Three demo logins are seeded (see the
/// sign-in screen). Passwords are stored in plain text because this is a local
/// demo store; the real build swaps in [FirebaseAuthRestService].
class LocalAuthService implements AuthService {
  static const _uuid = Uuid();
  static const _sessionKey = 'session_uid';

  final BackendService backend;
  LocalAuthService(this.backend);

  late final Box _creds; // email -> { uid, password }
  AppUser? _current;

  @override
  AppUser? get currentUser => _current;

  @override
  Future<void> init() async {
    _creds = await Hive.openBox('auth_creds');
    if (_creds.get('_seeded') != true) {
      for (final u in DemoSeed.users()) {
        await _creds.put(u.email.toLowerCase(), {
          'uid': u.id,
          'password': DemoSeed.demoPasswords[u.email] ?? 'spotwise',
        });
      }
      await _creds.put('_seeded', true);
    }

    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString(_sessionKey);
    if (uid != null) {
      _current = await backend.getUser(uid);
    }
  }

  @override
  Future<AppUser> signIn(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final key = email.trim().toLowerCase();
    final record = _creds.get(key);
    if (record == null) {
      throw const AuthException('No account found for that email.');
    }
    final map = Map<dynamic, dynamic>.from(record as Map);
    if (map['password'] != password) {
      throw const AuthException('Incorrect password. Please try again.');
    }
    final user = await backend.getUser(map['uid'].toString());
    if (user == null) {
      throw const AuthException('That account could not be loaded.');
    }
    await _persistSession(user.id);
    _current = user;
    return user;
  }

  @override
  Future<AppUser> register(
    String name,
    String email,
    String password, {
    UserRole role = UserRole.user,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final key = email.trim().toLowerCase();
    if (_creds.containsKey(key)) {
      throw const AuthException('An account already exists for that email.');
    }
    final uid = _uuid.v4();
    final user = AppUser(
      id: uid,
      name: name.trim(),
      email: key,
      role: role,
      createdAt: DateTime.now(),
    );
    await backend.saveUser(user);
    await _creds.put(key, {'uid': uid, 'password': password});
    await _persistSession(uid);
    _current = user;
    return user;
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    await Future.delayed(const Duration(milliseconds: 300));
    // Local mode can't email; we simply confirm so the flow is demoable.
  }

  @override
  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
    _current = null;
  }

  @override
  void cacheUser(AppUser user) => _current = user;

  Future<void> _persistSession(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionKey, uid);
  }
}
