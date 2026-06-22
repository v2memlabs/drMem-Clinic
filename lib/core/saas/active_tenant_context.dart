import 'membership.dart';
import 'tenant.dart';
import 'user_profile.dart';

/// Oturumdaki aktif tenant + kullanıcı bağlamı (SaaS-ready).
class ActiveTenantContext {
  final Tenant tenant;
  final Membership membership;
  final UserProfile profile;

  const ActiveTenantContext({
    required this.tenant,
    required this.membership,
    required this.profile,
  });

  String get tenantId => tenant.id;
  String get userId => profile.userId;
  String get role => membership.role;
}
