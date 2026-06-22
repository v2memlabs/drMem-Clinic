import 'session_bootstrap.dart';

/// [MembershipLoader] çıktısı — profil + üyelik listesi.
class MembershipLoadResult {
  final SessionBootstrapStatus status;
  final AuthenticatedProfile? profile;
  final List<AuthenticatedMembership> memberships;

  const MembershipLoadResult({
    required this.status,
    this.profile,
    this.memberships = const [],
  });

  bool get hasProfile => profile != null;

  factory MembershipLoadResult.profileMissing() {
    return const MembershipLoadResult(
      status: SessionBootstrapStatus.profileMissing,
    );
  }

  factory MembershipLoadResult.backendNotConfigured() {
    return const MembershipLoadResult(
      status: SessionBootstrapStatus.backendNotConfigured,
    );
  }

  factory MembershipLoadResult.loaded({
    required AuthenticatedProfile profile,
    required List<AuthenticatedMembership> memberships,
  }) {
    return MembershipLoadResult(
      status: SessionBootstrapStatus.notLoaded,
      profile: profile,
      memberships: memberships,
    );
  }
}
