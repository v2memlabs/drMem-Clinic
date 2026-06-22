import '../constants/app_roles.dart';
import 'active_tenant_selector.dart';

/// Login sonrası profil + membership yükleme durumu.
enum SessionBootstrapStatus {
  /// Profil + tek aktif membership; active tenant seçildi.
  ready,

  /// Bakım operatörü — aktif klinik üyelik gerekmez.
  maintenanceReady,

  /// Bakım operatörü — bu ortamda bakım modu kapalı.
  maintenanceAccessUnavailable,

  /// Birden fazla aktif membership — tenant picker (sonraki faz).
  needsTenantSelection,

  /// Üyelik kaydı yok.
  noMembership,

  /// Membership status aktif değil.
  inactiveMembership,

  /// Tenant status aktif değil.
  inactiveTenant,

  /// DB rolü eşlenemedi.
  unknownRole,

  /// Profil bulunamadı.
  profileMissing,

  /// Supabase / remote henüz yapılandırılmadı.
  backendNotConfigured,

  /// Henüz yüklenmedi (legacy).
  notLoaded,

  /// Davet kabul edilemedi.
  invitationAcceptFailed,

  /// Birden fazla bekleyen davet.
  multiplePendingInvitations,
}

/// Auth kullanıcısına bağlı profil özeti (Supabase `profiles` ile uyumlu).
class AuthenticatedProfile {
  final String profileId;
  final String displayName;
  final String? email;
  final String? loginUsername;
  final bool maintenanceOperator;

  const AuthenticatedProfile({
    required this.profileId,
    required this.displayName,
    this.email,
    this.loginUsername,
    this.maintenanceOperator = false,
  });

  String get preferredLoginIdentity =>
      (loginUsername != null && loginUsername!.trim().isNotEmpty)
          ? loginUsername!.trim()
          : (email ?? profileId);
}

/// Tenant üyeliği özeti (`memberships` + `tenants` join sonrası).
class AuthenticatedMembership {
  final String membershipId;
  final String tenantId;
  final String tenantName;
  final String? tenantSpecialty;
  final String dbRole;
  final String flutterRole;
  final String status;
  final String tenantStatus;

  const AuthenticatedMembership({
    required this.membershipId,
    required this.tenantId,
    required this.tenantName,
    this.tenantSpecialty,
    required this.dbRole,
    required this.flutterRole,
    this.status = 'active',
    this.tenantStatus = 'active',
  });

  bool get isActive => status == 'active';

  bool get isTenantActive => tenantStatus == 'active';
}

/// Bootstrap sonrası oturum bağlamı — [AuthSessionBridge] ve tenant store için.
class SessionBootstrapContext {
  final AuthenticatedProfile profile;
  final List<AuthenticatedMembership> memberships;
  final String activeTenantId;
  final String activeFlutterRole;
  final bool isMaintenanceOnly;

  const SessionBootstrapContext({
    required this.profile,
    required this.memberships,
    required this.activeTenantId,
    required this.activeFlutterRole,
    this.isMaintenanceOnly = false,
  });

  /// IT bakım operatörü — tenant bağlamı yok.
  factory SessionBootstrapContext.maintenanceOperator({
    required AuthenticatedProfile profile,
  }) {
    return SessionBootstrapContext(
      profile: profile,
      memberships: const [],
      activeTenantId: '',
      activeFlutterRole: AppRoles.maintenanceOperator,
      isMaintenanceOnly: true,
    );
  }

  /// [ActiveTenantSelector.resolve] üzerinden tek aktif membership seçimi.
  static SessionBootstrapContext? fromMemberships({
    required AuthenticatedProfile profile,
    required List<AuthenticatedMembership> memberships,
  }) {
    return ActiveTenantSelector.resolve(
      profile: profile,
      memberships: memberships,
    ).context;
  }
}

/// Profil + membership yükleme işinin sonucu.
class SessionBootstrapResult {
  final SessionBootstrapStatus status;
  final SessionBootstrapContext? context;

  const SessionBootstrapResult({
    required this.status,
    this.context,
  });

  factory SessionBootstrapResult.notLoaded() {
    return const SessionBootstrapResult(status: SessionBootstrapStatus.notLoaded);
  }

  factory SessionBootstrapResult.ready(SessionBootstrapContext context) {
    return SessionBootstrapResult(
      status: SessionBootstrapStatus.ready,
      context: context,
    );
  }

  factory SessionBootstrapResult.noMembership() {
    return const SessionBootstrapResult(status: SessionBootstrapStatus.noMembership);
  }

  factory SessionBootstrapResult.inactiveMembership() {
    return const SessionBootstrapResult(
      status: SessionBootstrapStatus.inactiveMembership,
    );
  }

  factory SessionBootstrapResult.inactiveTenant() {
    return const SessionBootstrapResult(status: SessionBootstrapStatus.inactiveTenant);
  }

  factory SessionBootstrapResult.unknownRole() {
    return const SessionBootstrapResult(status: SessionBootstrapStatus.unknownRole);
  }

  factory SessionBootstrapResult.profileMissing() {
    return const SessionBootstrapResult(status: SessionBootstrapStatus.profileMissing);
  }

  factory SessionBootstrapResult.backendNotConfigured() {
    return const SessionBootstrapResult(
      status: SessionBootstrapStatus.backendNotConfigured,
    );
  }

  factory SessionBootstrapResult.needsTenantSelection() {
    return const SessionBootstrapResult(
      status: SessionBootstrapStatus.needsTenantSelection,
    );
  }

  factory SessionBootstrapResult.maintenanceReady(SessionBootstrapContext context) {
    return SessionBootstrapResult(
      status: SessionBootstrapStatus.maintenanceReady,
      context: context,
    );
  }

  factory SessionBootstrapResult.maintenanceAccessUnavailable() {
    return const SessionBootstrapResult(
      status: SessionBootstrapStatus.maintenanceAccessUnavailable,
    );
  }

  factory SessionBootstrapResult.invitationAcceptFailed() {
    return const SessionBootstrapResult(
      status: SessionBootstrapStatus.invitationAcceptFailed,
    );
  }

  factory SessionBootstrapResult.multiplePendingInvitations() {
    return const SessionBootstrapResult(
      status: SessionBootstrapStatus.multiplePendingInvitations,
    );
  }

  bool get isReady =>
      status == SessionBootstrapStatus.ready && context != null;

  bool get isMaintenanceReady =>
      status == SessionBootstrapStatus.maintenanceReady && context != null;

  bool get isSuccess => isReady || isMaintenanceReady;
}
