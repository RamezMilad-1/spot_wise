import '../../models/app_user.dart';
import '../../models/enums.dart';

/// Authentication contract. Implemented by [LocalAuthService] (default) and
/// [FirebaseAuthRestService] (auto-activated when `FIREBASE_API_KEY` is set).
abstract class AuthService {
  Future<void> init();

  /// The signed-in user, or null. Available synchronously after [init].
  AppUser? get currentUser;

  Future<AppUser> signIn(String email, String password);

  Future<AppUser> register(
    String name,
    String email,
    String password, {
    UserRole role = UserRole.user,
  });

  Future<void> sendPasswordReset(String email);

  Future<void> signOut();

  /// Refresh the cached current user after a profile edit.
  void cacheUser(AppUser user);
}
