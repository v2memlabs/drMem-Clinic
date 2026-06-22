import '../saas/active_tenant_context.dart';

/// Active tenant yükleme başarısızlık nedenleri.
enum ActiveTenantLoadFailure {
  unknownRole,
  inactiveMembership,
  membershipNotFound,
  backendNotConfigured,
  notSupportedInMockMode,
}

/// [ActiveTenantContextLoader] çıktısı.
class ActiveTenantLoadResult {
  final bool success;
  final ActiveTenantContext? context;
  final ActiveTenantLoadFailure? failure;

  const ActiveTenantLoadResult._({
    required this.success,
    this.context,
    this.failure,
  });

  factory ActiveTenantLoadResult.loaded(ActiveTenantContext context) {
    return ActiveTenantLoadResult._(
      success: true,
      context: context,
    );
  }

  factory ActiveTenantLoadResult.failure(ActiveTenantLoadFailure reason) {
    return ActiveTenantLoadResult._(
      success: false,
      failure: reason,
    );
  }
}
