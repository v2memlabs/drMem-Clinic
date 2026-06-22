import '../../features/settings/models/tenant_financial_feature_settings.dart';

/// Oturum kapsamında tenant finansal özellik bayrakları.
abstract final class TenantFinancialFeatureGate {
  static TenantFinancialFeatureSettings _settings =
      TenantFinancialFeatureSettings.defaults;

  static TenantFinancialFeatureSettings get settings => _settings;

  static void apply(TenantFinancialFeatureSettings settings) {
    _settings = settings;
  }

  static void reset() {
    _settings = TenantFinancialFeatureSettings.defaults;
  }

  static bool isEnabled(TenantFinancialFeatureKey key) =>
      _settings.isEnabled(key);

  static bool get paymentRecordsEnabled =>
      isEnabled(TenantFinancialFeatureKey.paymentRecords);

  static bool get encounterPaymentStepEnabled =>
      paymentRecordsEnabled &&
      isEnabled(TenantFinancialFeatureKey.encounterPaymentStep);

  static bool get surgicalQuotePricingEnabled =>
      isEnabled(TenantFinancialFeatureKey.surgicalQuotePricing);

  static bool get surgicalQuoteAlertsEnabled =>
      surgicalQuotePricingEnabled &&
      isEnabled(TenantFinancialFeatureKey.surgicalQuoteAlerts);

  static bool get assistantFinanceNotificationsEnabled =>
      isEnabled(TenantFinancialFeatureKey.assistantFinanceNotifications);

  static bool get materialChargesEnabled =>
      paymentRecordsEnabled &&
      isEnabled(TenantFinancialFeatureKey.materialCharges);

  static bool get rehabPackagePricingEnabled =>
      paymentRecordsEnabled &&
      isEnabled(TenantFinancialFeatureKey.rehabPackagePricing);
}
