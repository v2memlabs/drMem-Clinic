import '../../../core/auth/auth_session.dart';
import '../../../core/tenant/tenant_financial_feature_gate.dart';

/// Ayarlar hub / route görünürlük yardımcıları.
bool clinicFinanceStatisticsVisible() =>
    AuthSession.canViewDoctorOnlySettings &&
    TenantFinancialFeatureGate.paymentRecordsEnabled;
