import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/features/settings/data/tenant_subscription_mapper.dart';

void main() {
  test('fromParts maps subscription and usage limits', () {
    final summary = TenantSubscriptionMapper.fromParts(
      subscriptionRow: {
        'plan_key': 'starter',
        'status': 'trialing',
        'current_period_end': '2027-01-15T00:00:00Z',
      },
      usageLimitRows: [
        {'metric_key': 'patient_records', 'limit_value': 120},
        {'metric_key': 'seats', 'limit_value': 8},
      ],
      seatUsed: 3,
      patientCount: 42,
    );

    expect(summary.planLabel, 'Başlangıç');
    expect(summary.statusLabel, 'Deneme');
    expect(summary.seatUsed, 3);
    expect(summary.seatLimit, 8);
    expect(summary.patientCount, 42);
    expect(summary.patientLimit, 120);
    expect(summary.renewalLabel, isNotNull);
  });

  test('fromParts applies default seat limit for demo plan', () {
    final summary = TenantSubscriptionMapper.fromParts(
      subscriptionRow: const {'plan_key': 'demo', 'status': 'active'},
      usageLimitRows: const [],
      seatUsed: 2,
      patientCount: 1,
    );

    expect(summary.seatLimit, 5);
    expect(summary.planLabel, 'Demo');
  });
}
