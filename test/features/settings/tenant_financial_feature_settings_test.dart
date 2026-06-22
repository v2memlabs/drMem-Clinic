import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/core/tenant/tenant_financial_feature_gate.dart';
import 'package:v2mem_clinic/features/settings/models/tenant_financial_feature_settings.dart';

void main() {
  tearDown(TenantFinancialFeatureGate.reset);

  test('fromJson reads financial flags with defaults', () {
    final settings = TenantFinancialFeatureSettings.fromJson({
      'financial': {
        'payment_records': false,
        'surgical_quote_pricing': false,
      },
    });

    expect(settings.isEnabled(TenantFinancialFeatureKey.paymentRecords), isFalse);
    expect(
      settings.isEnabled(TenantFinancialFeatureKey.encounterPaymentStep),
      isTrue,
    );
    expect(
      settings.isEnabled(TenantFinancialFeatureKey.surgicalQuotePricing),
      isFalse,
    );
  });

  test('gate derives dependent flags from payment records', () {
    TenantFinancialFeatureGate.apply(
      TenantFinancialFeatureSettings(
        flags: {
          TenantFinancialFeatureKey.paymentRecords: false,
          TenantFinancialFeatureKey.encounterPaymentStep: true,
          TenantFinancialFeatureKey.materialCharges: true,
          TenantFinancialFeatureKey.rehabPackagePricing: true,
          TenantFinancialFeatureKey.surgicalQuotePricing: true,
          TenantFinancialFeatureKey.surgicalQuoteAlerts: true,
          TenantFinancialFeatureKey.assistantFinanceNotifications: true,
        },
      ),
    );

    expect(TenantFinancialFeatureGate.paymentRecordsEnabled, isFalse);
    expect(TenantFinancialFeatureGate.encounterPaymentStepEnabled, isFalse);
    expect(TenantFinancialFeatureGate.materialChargesEnabled, isFalse);
    expect(TenantFinancialFeatureGate.rehabPackagePricingEnabled, isFalse);
  });

  test('toJson round-trips storage keys', () {
    final original = TenantFinancialFeatureSettings.defaults.copyWithFlag(
      TenantFinancialFeatureKey.assistantFinanceNotifications,
      false,
    );
    final json = original.toJson();
    final restored = TenantFinancialFeatureSettings.fromJson({'financial': json});

    expect(
      restored.isEnabled(
        TenantFinancialFeatureKey.assistantFinanceNotifications,
      ),
      isFalse,
    );
  });
}
