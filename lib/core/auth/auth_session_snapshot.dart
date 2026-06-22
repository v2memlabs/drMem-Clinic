import '../../shared/models/app_user.dart';

/// Pasif oturum okuması — [AuthRepositoryContract.currentSession].
class AuthSessionSnapshot {
  final bool isLoggedIn;
  final AppUser? user;

  const AuthSessionSnapshot({
    required this.isLoggedIn,
    this.user,
  });

  factory AuthSessionSnapshot.empty() {
    return const AuthSessionSnapshot(isLoggedIn: false);
  }

  factory AuthSessionSnapshot.fromUser(AppUser? user) {
    return AuthSessionSnapshot(
      isLoggedIn: user != null,
      user: user,
    );
  }
}
