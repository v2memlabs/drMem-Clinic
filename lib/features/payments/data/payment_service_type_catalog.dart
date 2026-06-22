import '../../../core/auth/auth_session.dart';
import '../../../core/constants/app_roles.dart';
import '../../../core/tenant/tenant_financial_feature_gate.dart';
import '../models/payment_record.dart';

/// Rol bazlı ödeme formu hizmet tipleri.
abstract final class PaymentServiceTypeCatalog {
  static List<ServiceType> allowedForCurrentUser() {
    final role = AuthSession.currentUser?.role;
    if (role == AppRoles.physiotherapist) {
      final types = <ServiceType>[
        ServiceType.fizyoterapi_seansi,
        ServiceType.diger,
      ];
      if (TenantFinancialFeatureGate.rehabPackagePricingEnabled) {
        types.insert(0, ServiceType.rehabilitasyon);
      }
      return types;
    }

    if (!TenantFinancialFeatureGate.rehabPackagePricingEnabled) {
      return ServiceType.values
          .where((t) => t != ServiceType.rehabilitasyon)
          .toList(growable: false);
    }
    return ServiceType.values;
  }
}
