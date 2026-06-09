import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/utils/error_handler.dart';
import '../models/app_user.dart';
import '../models/enums.dart';
import '../services/service_locator.dart';

/// Owns the signed-in user and all user-state mutations (profile, saved spots).
class AuthProvider extends ChangeNotifier {
  AppUser? _user;
  bool _busy = false;
  String? _error;

  AppUser? get user => _user;
  bool get isLoggedIn => _user != null;
  bool get busy => _busy;
  String? get error => _error;
  UserRole get role => _user?.role ?? UserRole.user;

  /// Restores any cached session captured during [ServiceLocator.init].
  void bootstrap() => _user = services.auth.currentUser;

  Future<bool> signIn(String email, String password) =>
      _run(() => services.auth.signIn(email, password));

  Future<bool> register(
    String name,
    String email,
    String password, {
    UserRole role = UserRole.user,
  }) =>
      _run(() => services.auth.register(name, email, password, role: role));

  Future<bool> _run(Future<AppUser> Function() action) async {
    _setBusy(true);
    _error = null;
    try {
      _user = await action();
      _setBusy(false);
      unawaited(registerPushToken());
      return true;
    } catch (e) {
      _error = friendlyError(e);
      _setBusy(false);
      return false;
    }
  }

  /// Saves this device's FCM token onto the signed-in user (so a server could
  /// target them later). No-op on web/desktop or when nothing changed.
  Future<void> registerPushToken() async {
    final user = _user;
    if (user == null) return;
    final token = await services.push.currentToken();
    if (token == null || token == user.fcmToken) return;
    final updated = user.copyWith(fcmToken: token);
    try {
      await services.backend.saveUser(updated);
      services.auth.cacheUser(updated);
      _user = updated;
      notifyListeners();
    } catch (_) {/* token sync is best-effort */}
  }

  Future<bool> sendPasswordReset(String email) async {
    _setBusy(true);
    _error = null;
    try {
      await services.auth.sendPasswordReset(email);
      _setBusy(false);
      return true;
    } catch (e) {
      _error = friendlyError(e);
      _setBusy(false);
      return false;
    }
  }

  Future<void> signOut() async {
    await services.auth.signOut();
    _user = null;
    notifyListeners();
  }

  Future<bool> updateProfile({
    String? name,
    List<String>? interests,
    String? homeCity,
    String? photoUrl,
  }) async {
    final current = _user;
    if (current == null) return false;
    final updated = current.copyWith(
      name: name,
      interests: interests,
      homeCity: homeCity,
      photoUrl: photoUrl,
    );
    try {
      await services.backend.saveUser(updated);
      services.auth.cacheUser(updated);
      _user = updated;
      notifyListeners();
      return true;
    } catch (e) {
      _error = friendlyError(e);
      notifyListeners();
      return false;
    }
  }

  // ── Saved spots ──────────────────────────────────────────────────────────
  bool isSaved(String spotId) => _user?.savedSpotIds.contains(spotId) ?? false;

  Future<void> toggleSave(String spotId) async {
    final current = _user;
    if (current == null) return;
    final ids = [...current.savedSpotIds];
    ids.contains(spotId) ? ids.remove(spotId) : ids.add(spotId);
    final updated = current.copyWith(savedSpotIds: ids);
    _user = updated;
    notifyListeners();
    try {
      await services.backend.saveUser(updated);
      services.auth.cacheUser(updated);
    } catch (_) {/* optimistic; stays saved locally */}
  }

  void clearError() {
    _error = null;
  }

  void _setBusy(bool value) {
    _busy = value;
    notifyListeners();
  }
}
